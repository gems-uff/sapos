# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionApplication < ActiveRecord::Base
  has_paper_trail

  APPROVED = record_i18n_attr("statuses.approved")
  REPROVED = record_i18n_attr("statuses.reproved")
  ERROR = record_i18n_attr("statuses.error")

  END_OF_PHASE_STATUSES = [APPROVED, REPROVED]
  STATUSES = [APPROVED, REPROVED, ERROR]

  scope :non_consolidated, -> {
    where(
      arel_table[:status].eq(nil).or(
        arel_table[:status].eq(ERROR)
      )
    )
  }

  scope :ready_for_consolidation, ->(phase_id, user_id = nil) {
    if phase_id.nil?
      non_consolidated.includes(:filled_form)
      .where(filled_form: { is_filled: true })
    else
      non_consolidated.where.not(
        id: Admissions::AdmissionPendency.pendencies(phase_id, user_id)
          .select(:admission_application_id)
      )
    end
  }

  scope :with_pendencies, ->(phase_id, user_id = nil) {
    if phase_id.nil?
      non_consolidated.includes(:filled_form)
      .where(filled_form: { is_filled: false })
    else
      non_consolidated.where(
        id: Admissions::AdmissionPendency.pendencies(phase_id, user_id)
          .select(:admission_application_id)
      )
    end
  }

  scope :without_committee, ->(phase_id) {
    where(
      id: Admissions::AdmissionPendency
        .missing_committee(phase_id)
        .select(:admission_application_id)
    )
  }

  has_many :letter_requests, dependent: :delete_all,
    class_name: "Admissions::LetterRequest"
  has_many :evaluations, dependent: :destroy,
    class_name: "Admissions::AdmissionPhaseEvaluation"
  has_many :results, dependent: :destroy,
    class_name: "Admissions::AdmissionPhaseResult"
  has_many :rankings, dependent: :destroy,
    class_name: "Admissions::AdmissionRankingResult"
  has_many :pendencies, dependent: :destroy,
    class_name: "Admissions::AdmissionPendency"

  belongs_to :admission_process, optional: false,
    class_name: "Admissions::AdmissionProcess"
  belongs_to :filled_form, optional: false,
    class_name: "Admissions::FilledForm"
  belongs_to :admission_phase, optional: true,
    class_name: "Admissions::AdmissionPhase"

  accepts_nested_attributes_for :filled_form,
    allow_destroy: true
  accepts_nested_attributes_for :letter_requests, reject_if: :all_blank,
    allow_destroy: true
  accepts_nested_attributes_for :evaluations
  accepts_nested_attributes_for :results

  validates :name, presence: true
  validates :email, presence: true
  validates_uniqueness_of :email, scope: :admission_process_id, if: ->(apply) {
    apply.admission_process.present? &&
    !apply.admission_process.allow_multiple_applications
  }

  validate :number_of_letters_in_filled_form

  before_save :set_token

  def self.pendency_condition(user = nil)
    user ||= current_user
    return ["0 = -1"] if user.blank?
    return ["0 = -1"] if user.cannot?(:read_pendencies, Admissions::AdmissionApplication)

    candidate_arel = Admissions::AdmissionApplication.arel_table
    pendency_arel = Admissions::AdmissionPendency.arel_table
    pendencies_query = pendency_arel.where(
      pendency_arel[:status].eq(Admissions::AdmissionPendency::PENDENT)
      .and(pendency_arel[:admission_phase_id].eq(candidate_arel[:admission_phase_id]))
      .and(pendency_arel[:user_id].eq(user.id))
    ).project(pendency_arel[:admission_application_id])
    [candidate_arel[:id].in(pendencies_query).to_sql]
  end

  def self.phase_condition(phase_id = nil)
    candidate_arel = Admissions::AdmissionApplication.arel_table
    [candidate_arel[:admission_phase_id].eq(phase_id).to_sql]
  end

  def number_of_letters_in_filled_form
    return if self.filled_form.blank?
    return if self.admission_process.blank?
    return if !self.admission_process.has_letters
    return if !self.filled_form.is_filled

    min_count = self.admission_process.min_letters.to_i
    max_count = self.admission_process.max_letters.to_i
    if self.letter_requests.length < min_count
      self.errors.add(:base, :min_letters, count: min_count)
    end
    if max_count > 0 && self.letter_requests.length > max_count
      self.errors.add(:base, :max_letters, count: max_count)
    end
  end

  def to_label
    "#{self.name} - #{self.token}"
  end

  def requested_letters
    self.letter_requests.count
  end

  def filled_letters
    self.letter_requests
       .includes(:filled_form)
       .where(filled_form: { is_filled: true }).count
  end

  def missing_letters?
    return false if !self.admission_process.has_letters
    filled_letters = self.letter_requests.count do |letter|
      letter.filled_form.is_filled
    end
    filled_letters < self.admission_process.min_letters.to_i
  end

  def prepare_missing_letters
    process = self.admission_process
    if process.has_letters
      min_letters = process.min_letters.to_i
      new_letters = min_letters - self.letter_requests.count
      if new_letters > 0
        new_letters.times do
          self.letter_requests.new
        end
      end
    end
  end

  def satisfies_condition(form_condition, fields: nil, should_raise: nil)
    Admissions::FormCondition.check_truth(
      form_condition, should_raise: should_raise
    ) do |name|
      next fields[name] if fields.present?
      (
        Admissions::FilledFormField.includes(:form_field)
          .includes(filled_form: :admission_phase_result)
          .where(
            filled_form: { admission_phase_results: {
              admission_application_id: self.id
            } },
            form_field: { name: name }
          ).order(updated_at: :desc, id: :desc).first ||
        Admissions::FilledFormField.includes(:form_field)
          .includes(filled_form: :admission_application)
          .where(
            filled_form: { admission_applications: { id: self.id } },
            form_field: { name: name }
          ).first
      )
    end
  end

  def fields_hash
    field_objects = self.filled_form.to_fields_hash
    self.results.each do |result|
      result.filled_form.to_fields_hash(field_objects)
    end
    field_objects
  end

  def consolidate_phase(phase)
    if phase.nil?
      return { status: APPROVED, status_message: nil }
    end
    field_objects = nil
    if phase.consolidation_form.present?
      field_objects = self.fields_hash
      committees = self.evaluations.where(admission_phase_id: phase.id).map do |ev|
        ev.filled_form.to_fields_hash.map(&:simple_value)
      end
      vars = {
        process: self.admission_process,
        application: self,
        committees: committees,
      }
      phase_result = Admissions::AdmissionPhaseResult.find_or_create_by(
        admission_phase_id: phase.id,
        admission_application: self,
        mode: Admissions::AdmissionPhaseResult::CONSOLIDATION
      )
      begin
        phase_result.filled_form.consolidate(
          field_objects: field_objects,
          vars: vars
        )
        phase_result.filled_form.is_filled = true
      rescue => err
        return { status: ERROR, status_message: err }
      ensure
        phase_result.save!
      end
    end
    begin
      if self.satisfies_condition(
        phase.approval_condition, fields: field_objects,
        should_raise: Admissions::FormCondition::RAISE_PHASE
      )
        { status: APPROVED, status_message: nil }
      else
        { status: REPROVED, status_message: nil }
      end
    rescue => err
      { status: ERROR, status_message: err }
    end
  end

  def consolidate_phase!(phase)
    result = self.consolidate_phase(phase)
    self.update!(result)
    result[:status]
  end

  def descriptive_status
    if self.status.present?
      return self.status if self.status_message.blank?
      return "#{self.status}: #{self.status_message}"
    end
    return "Sem comitê válido" if self.pendencies.where(
      admission_phase_id: self.admission_phase_id,
      user_id: nil
    ).first.present?
    pendencies = []
    if self.pendencies.where(
      admission_phase_id: self.admission_phase_id,
      mode: Admissions::AdmissionPendency::SHARED,
      status: Admissions::AdmissionPendency::PENDENT
    ).first.present?
      pendencies << "Compartilhado"
    end
    self.pendencies.where(
      admission_phase_id: self.admission_phase_id,
      mode: Admissions::AdmissionPendency::MEMBER,
      status: Admissions::AdmissionPendency::PENDENT
    ).each do |pendency|
      pendencies << pendency.user.name
    end
    return "Pendente: #{pendencies.join(", ")}" if pendencies.present?
    return "Pendente" if self.admission_phase_id.nil? && !self.filled_form.is_filled
    "Pronto para consolidação"
  end

  def candidate_can_edit?
    return self.admission_process.is_open? if !self.filled_form.is_filled
    self.admission_process.is_open_to_edit?
  end

  private
    def generate_token
      18.times.map { "2346789BCDFGHJKMPQRTVWXY".split("").sample }
        .insert(6, "-").insert(13, "-").join("")
    end

    def generate_valid_token
      token = generate_token
      while Admissions::AdmissionApplication.exists?(token: token) ||
          Admissions::AdmissionApplication.where(
            "admission_process_id = ? AND token LIKE ?",
            self.admission_process_id, "#{token[..6]}%"
          ).first.present?
        # Token must be globally unique
        # First 6 digits of token must be unique for process
        token = generate_token
      end
      token
    end

    def set_token
      unless self.token?
        self.token = generate_valid_token
      end
    end
end
