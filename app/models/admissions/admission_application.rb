# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionApplication < ActiveRecord::Base
  has_paper_trail

  APPROVED = record_i18n_attr("statuses.approved")
  REPROVED = record_i18n_attr("statuses.reproved")
  ERROR = record_i18n_attr("statuses.error")

  has_many :letter_requests, dependent: :delete_all,
    class_name: "Admissions::LetterRequest"
  has_many :evaluations, dependent: :destroy,
    class_name: "Admissions::AdmissionPhaseEvaluation"
  has_many :results, dependent: :destroy,
    class_name: "Admissions::AdmissionPhaseResult"

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

  def satisfies_conditions(form_conditions)
    form_conditions.all? do |condition|
      field = (
        Admissions::FilledFormField.includes(:form_field)
          .includes(filled_form: :admission_phase_result)
          .where(
            filled_form: { admission_phase_results: {
              admission_application_id: self.id
            } },
            form_field: { name: condition.field }
          ).order(updated_at: :desc, id: :desc).first ||
        Admissions::FilledFormField.includes(:form_field)
          .includes(filled_form: :admission_application)
          .where(
            filled_form: { admission_applications: { id: self.id } },
            form_field: { name: condition.field }
          ).first
      )
      next false if field.blank?
      func = Admissions::FormCondition::OPTIONS[condition.condition]
      if field.file.present?
        func.call(field.file, condition.value)
      elsif field.list.present?
        field.list.any? do |element|
          func.call(element, condition.value)
        end
      else
        func.call(field.value, condition.value)
      end
    end
  end

  def consolidate_phase(phase)
    if phase.nil?
      return record_i18n_attr("statuses.approved")
    end
    if phase.consolidation_form.present?
      fields = self.filled_form.to_fields_hash
      self.results.each do |result|
        result.filled_form.to_fields_hash(fields)
      end
      committees = self.evaluations.where(admission_phase_id: phase.id).map do |ev|
        ev.filled_form.to_fields_hash
      end
      phase_result = Admissions::AdmissionPhaseResult.find_or_create_by(
        admission_phase_id: phase.id,
        admission_application: self,
        mode: Admissions::AdmissionPhaseResult::CONSOLIDATION
      )
      cfields = phase_result.filled_form.form_template.fields.order(:order)
      cfield_hash = cfields.index_by(&:id)
      field_ids = cfields.map(&:id)
      filled_field_ids = phase_result.filled_form.fields.map(&:form_field_id)

      new_filled_fields = field_ids - filled_field_ids
      new_filled_fields.each do |field_id|
        form_field = cfield_hash[field_id]
        configuration = JSON.parse(form_field.configuration || "{}")
        if form_field.field_type == Admissions::FormField::CODE
          begin
            value = self.evaluate_code(
              configuration["code"],
              process: self.admission_process,
              application: self,
              fields: fields,
              committees: committees,
            )
            phase_result.filled_form.fields.new(
              form_field_id: field_id, value: value
            )
          rescue => err
            phase_result.save!
            return "#{record_i18n_attr("statuses.error")}: #{err}"
          end
        end
      end
    end
    phase_result.save!
    if self.satisfies_conditions(phase.form_conditions)
      record_i18n_attr("statuses.approved")
    else
      record_i18n_attr("statuses.reproved")
    end
  end

  def consolidate_phase!(phase)
    result = self.consolidate_phase(phase)
    self.update!(status: result)
    result
  end

  private
    def evaluate_code(formula, **bindings)
      b = binding
      bindings.each do |var, val| b.local_variable_set(var, val) end

      b.eval(formula)
    end

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
