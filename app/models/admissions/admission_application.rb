# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionApplication < ActiveRecord::Base
  has_paper_trail

  attr_accessor :non_persistent

  APPROVED = record_i18n_attr("statuses.approved")
  REPROVED = record_i18n_attr("statuses.reproved")
  CANCELED = record_i18n_attr("statuses.canceled")
  ERROR = record_i18n_attr("statuses.error")

  SHADOW_FIELDS = Set[
    "name", "token", "email", "status", "identifier", "phase_name",
    "requested_letters", "filled_letters"
  ]
  SHADOW_FIELDS_MAP = SHADOW_FIELDS.index_by do |field|
    record_i18n_attr(field)
  end

  END_OF_PHASE_STATUSES = [APPROVED, REPROVED, CANCELED]
  STATUSES = [APPROVED, REPROVED, CANCELED, ERROR]

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

  # The following scopes are used dinamically by _phase_status_form.html.erb
  scope :fill_pendency, ->(phase_id) {
    non_consolidated.includes(:filled_form)
      .where(filled_form: { is_filled: false })
  }

  scope :missing_committee, ->(phase_id) { non_consolidated.where(
    id: Admissions::AdmissionPendency.missing_committee(phase_id)
      .select(:admission_application_id)
  )}

  scope :member_pendency, ->(phase_id) { non_consolidated.where(
    id: Admissions::AdmissionPendency.member_pendency(phase_id)
      .select(:admission_application_id)
  )}

  scope :shared_pendency, ->(phase_id) { non_consolidated.where(
    id: Admissions::AdmissionPendency.shared_pendency(phase_id)
      .select(:admission_application_id)
  )}

  scope :candidate_pendency, ->(phase_id) { non_consolidated.where(
    id: Admissions::AdmissionPendency.candidate_pendency(phase_id)
      .select(:admission_application_id)
  )}

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
  belongs_to :student, optional: true
  belongs_to :enrollment, optional: true


  accepts_nested_attributes_for :filled_form,
    allow_destroy: true
  accepts_nested_attributes_for :letter_requests, reject_if: :all_blank,
    allow_destroy: true
  accepts_nested_attributes_for :evaluations
  accepts_nested_attributes_for :results
  accepts_nested_attributes_for :rankings

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

  def satisfies_condition(form_condition, fields: nil, should_raise: nil, default: true)
    Admissions::FormCondition.check_truth(
      form_condition, should_raise: should_raise, default: default
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
          ).first ||
        Admissions::FilledFormField.includes(:form_field)
          .includes(filled_form: :admission_ranking_result)
          .where(
            filled_form: { admission_ranking_results: {
              admission_application_id: self.id
            } },
            form_field: { name: name }
          ).order(updated_at: :desc, id: :desc).first ||
        self.attribute_as_field(name.to_s)
      )
    end
  end

  def attribute_as_field(attrib, attrib_name: nil)
    attrib = SHADOW_FIELDS_MAP[attrib] || attrib
    return nil if !SHADOW_FIELDS.include? attrib
    attrib_name ||= record_i18n_attr(attrib)
    Admissions::FilledFormField.new(
      value: self.send(attrib),
      form_field: Admissions::FormField.new(
        name: attrib_name,
        field_type: Admissions::FormField::STRING
      )
    )
  end

  def fields_hash
    field_objects = {}
    SHADOW_FIELDS.each do |attrib|
      [attrib.to_s, record_i18n_attr(attrib)].each do |attrib_name|
        field_objects[attrib_name] = self.attribute_as_field(attrib, attrib_name:)
      end
    end
    self.filled_form.to_fields_hash(field_objects)
    self.results.each do |result|
      result.filled_form.to_fields_hash(field_objects)
    end
    self.ordered_rankings.each do |ranking|
      ranking.filled_form.to_fields_hash(field_objects)
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
      committees = self.evaluations.where(admission_phase_id: phase.id).filter_map do |ev|
        next if !ev.filled_form.is_filled
        ev.filled_form.to_fields_hash.transform_values do |v|
          v.simple_value
        end
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
      elsif self.satisfies_condition(
        phase.keep_in_phase_condition, fields: field_objects,
        should_raise: Admissions::FormCondition::RAISE_PHASE,
        default: false
      )
        {}
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
    pendencies = []
    [
      Admissions::AdmissionPendency::SHARED,
      Admissions::AdmissionPendency::CANDIDATE,
    ].each do |pendency_mode|
      if self.pendencies.where(
        admission_phase_id: self.admission_phase_id,
        mode: pendency_mode,
        status: Admissions::AdmissionPendency::PENDENT
      ).first.present?
        pendencies << pendency_mode
      end
    end
    if self.pendencies.where(
      admission_phase_id: self.admission_phase_id,
      user_id: nil,
      mode: Admissions::AdmissionPendency::MEMBER
    ).first.present?
      pendencies << "Sem comitê válido"
    else
      self.pendencies.where(
        admission_phase_id: self.admission_phase_id,
        mode: Admissions::AdmissionPendency::MEMBER,
        status: Admissions::AdmissionPendency::PENDENT
      ).each do |pendency|
        pendencies << pendency.user.name
      end
    end
    return "Pendente: #{pendencies.join(", ")}" if pendencies.present?
    return "Pendente" if self.admission_phase_id.nil? && !self.filled_form.is_filled
    "Pronto para consolidação"
  end

  def candidate_can_edit
    if !self.filled_form.is_filled
      return nil if !self.admission_process.is_open?
      return [:new, {}]
    end
    candidate_form = self.admission_phase.try(:candidate_form)
    if candidate_form.present?
      existing = self.results.where(
        admission_phase_id: self.admission_phase_id,
        mode: Admissions::AdmissionPhaseResult::CANDIDATE
      ).first
      if existing.blank? || !existing.filled_form.is_filled
        return [:new_phase, phase: self.phase_name]
      else
        return [:edit_phase, phase: self.phase_name]
      end
    end
    return [:edit, {}] if self.admission_process.is_open_to_edit?
    # ToDo: :edit if edit is enabled for candidate
    nil
  end

  def students_by_cpf
    cpf = self.filled_form.try(:find_cpf_field).try(:value)
    return Student.none if cpf.blank?
    cpf = cpf.delete(".").delete("-").strip
    Student.where('
      TRIM(REPLACE(
        REPLACE(`students`.`cpf` COLLATE :db_collation, ".", ""),
        "-", ""
      )) = :cpf COLLATE :value_collation
    ', Collation.collations.merge(cpf:))
  end

  def students_by_email
    email = self.email.strip.downcase
    Student.where('
      TRIM(
        LOWER(`students`.`email` COLLATE :db_collation)
      ) = :email COLLATE :value_collation
    ', Collation.collations.merge(email:))
  end

  def students
    by_cpf = self.students_by_cpf.all
    by_email = self.students_by_email.all
    by_cpf_and_email = by_cpf & by_email
    by_cpf = by_cpf - by_cpf_and_email
    by_email = by_email - by_cpf_and_email
    result = {}
    result[:cpf_and_email] = by_cpf_and_email if by_cpf_and_email.present?
    result[:cpf] = by_cpf if by_cpf.present?
    result[:email] = by_email if by_email.present?
    result
  end

  def assign_form(
    params,
    has_letter_forms: false,
    has_phases: false,
    has_rankings: false,
    can_edit_override: false,
    check_candidate_permission: false,
    committee_permission_user: nil
  )
    self.assign_attributes(params)
    all_forms = []
    all_phase_forms = []
    if self.filled_form.try(:enable_submission) == "1"
      self.filled_form.prepare_missing_fields
      self.filled_form.sync_fields_after(self)
      all_forms << {
        was_filled: self.filled_form.is_filled,
        mode: :main,
        object: self
      }
      self.filled_form.is_filled = true
    end
    if has_letter_forms
      self.letter_requests.each do |letter_request|
        if letter_request.filled_form.try(:enable_submission) == "1"
          letter_request.filled_form.sync_fields_after(letter_request)
          all_forms << {
            was_filled: letter_request.filled_form.is_filled,
            mode: :letter,
            object: letter_request
          }
          letter_request.filled_form.is_filled = true
        end
      end
    end
    if has_phases
      self.admission_process.phases.order(:order).each do |p|
        phase = p.admission_phase
        app_forms = phase.prepare_application_forms(
          self,
          can_edit_override:,
          check_candidate_permission:,
          committee_permission_user:
        )
        app_forms[:phase_forms].each do |phase_form|
          # Do not solve pendency if form was not available to user
          next if !phase_form[:can_edit_form]
          # Do not solve pendency if it was not created by assign_attributes
          next if phase_form[:from_build]
          # Do not solve pendency if form submission was disabled
          next if phase_form[:object].filled_form.try(:enable_submission) != "1"
          phase_form[:was_filled] = phase_form[:object].filled_form.is_filled
          phase_form[:object].filled_form.is_filled = true
          all_phase_forms << phase_form
          all_forms << phase_form
        end
        break if app_forms[:latest_available_phase]
      end
    end
    if has_rankings
      self.ordered_rankings.each do |ranking|
        next if !ranking.filled_form.is_filled
        next if !can_edit_override
        next if ranking.filled_form.try(:enable_submission) != "1"
        ranking.filled_form.prepare_missing_fields
        all_forms << {
          was_filled: ranking.filled_form.is_filled,
          mode: :ranking,
          object: ranking
        }
        ranking.filled_form.is_filled = true
      end
    end

    if self.valid?
      all_phase_forms.each do |phase_form|
        pendency_success = phase_form[:pendency_success]
        next if pendency_success.blank?
        Admissions::AdmissionPendency.where(pendency_success).update_all(
          status: Admissions::AdmissionPendency::OK
        )
      end
    else
      all_forms.each do |form|
        form[:object].filled_form.is_filled = form[:was_filled]
      end
    end
  end

  def update_student(student, field_objects: nil, only_photo: false)
    field_objects ||= self.fields_hash
    sync_name = nil
    sync_email = nil
    update_log = []
    field_objects.each do |key, filled_field|
      form_field = filled_field.form_field
      sync_name = filled_field if form_field.sync == Admissions::FormField::SYNC_NAME
      sync_email = filled_field if form_field.sync == Admissions::FormField::SYNC_EMAIL
      next if form_field.field_type != Admissions::FormField::STUDENT_FIELD
      config = form_field.config_hash
      student_field = config["field"]
      next if only_photo && student_field != "photo"
      sync_name = false if student_field == "name"
      sync_email = false if student_field == "email"
      if student_field == "photo"
        if filled_field.file.present? && filled_field.file.file.present?
          if student.photo.file.present? && filled_field.file.identifier != student.photo.identifier
            old_url = Rails.application.routes.url_helpers.download_path(
              student.photo.medium_hash,
            )
            update_log << "#{form_field.name}/Foto alterada. Foto anterior: #{old_url}"
          end
          student.photo.retrieve_from_store!(filled_field.file.identifier)
        end
      elsif student.has_attribute?(student_field)
        filled_field.set_model_field(update_log, student, student_field)
      elsif student_field == "special_address"
        simple = filled_field.simple_value.split(" <$> ").join(", ")
        filled_field.set_model_field(update_log, student, "address", simple:)
      elsif student_field == "special_city"
        values = (filled_field.value || "").split(" <$> ")
        (3 - values.length).times { values << "" }
        if values.any? { |x| x.present? }
          filled_field.set_model_place_field(
            City, nil, update_log, student, "city",
            "#{form_field.name}/Cidade de candidatura não encontrada: #{values.join(", ")}",
            city: values[0], state: values[1], country: values[2]
          )
        end
      elsif student_field == "special_birth_city"
        values = (filled_field.value || "").split(" <$> ")
        (3 - values.length).times { values << "" }
        if values.any? { |x| x.present? }
          city = filled_field.set_model_place_field(
            City, nil, update_log, student, "birth_city",
            "#{form_field.name}/Cidade de candidatura não encontrada: #{values.join(", ")}",
            city: values[0], state: values[1], country: values[2]
          )
          state = filled_field.set_model_place_field(
            State, city.try(:state), update_log, student, "birth_state",
            "#{form_field.name}/Estado de candidatura não encontrado: #{values[1..].join(", ")}",
            state: values[1], country: values[2]
          )
          filled_field.set_model_place_field(
            Country, state.try(:country), update_log, student, "birth_country",
            "#{form_field.name}/País de candidatura não encontrado: #{values[2]}",
            country: values[2]
          )
        end
      elsif student_field == "special_majors"
        student_majors = student.majors
        filled_field.scholarities.each do |scholarity|
          major = Major.search_name(
            major: scholarity.course,
            institution: scholarity.institution,
            level: scholarity.level
          ).first
          if major.nil?
            update_log << "#{form_field.name}/Curso não encontrado: #{scholarity.to_label}"
          elsif !student_majors.include? major
            student.student_majors.build(major:)
          end
        end
      else
        raise Exceptions::InvalidStudentFieldException.new(
          "Campo de Aluno não encontrado: #{student_field}"
        )
      end
    end
    return if only_photo
    sync_name = self.attribute_as_field("name") if sync_name.nil?
    sync_email = self.attribute_as_field("email") if sync_email.nil?
    sync_name.set_model_field(update_log, student, "name") if sync_name
    sync_email.set_model_field(update_log, student, "email") if sync_email
    if update_log.present?
      student.obs = "" if student.obs.nil?
      student.obs += "\n" if student.obs.present?
      student.obs += "Candidatura #{self.to_label}: \n- #{update_log.join("\n- ")}"
    end
  end

  def update_enrollment(enrollment, field_objects: nil)
    process = self.admission_process
    update_log = []
    [:level, :enrollment_status, :admission_date].each do |attrib|
      process_value = process.send(attrib)
      next if process_value.blank?
      enrollment_value = enrollment.send(attrib)
      if enrollment_value.present? && process_value != enrollment_value
        message = "#{enrollment.class.record_i18n_attr(attrib)} alterado."
        value_s = attrib != :admission_date ? enrollment_value.to_label : enrollment_value.to_s
        message += " Valor anterior: #{value_s}"
        update_log << message
      end
      enrollment.assign_attributes(attrib => process_value)
    end
    if process.enrollment_number_field.present?
      field_objects ||= self.fields_hash
      filled_field = field_objects[process.enrollment_number_field]
      raise Exceptions::MissingFieldException.new(
        "Campo de número da matrícula definido no edital não encontrado em candidato: #{process.enrollment_number_field}"
      ) if filled_field.blank?
      filled_field.set_model_field(update_log, enrollment, :enrollment_number)
    end
    if update_log.present?
      enrollment.obs = "" if enrollment.obs.nil?
      enrollment.obs += "\n" if enrollment.obs.present?
      enrollment.obs += "Candidatura #{self.to_label}: \n- #{update_log.join("\n- ")}"
    end
  end

  def undo_consolidation
    if END_OF_PHASE_STATUSES.include?(self.status)
      set_phase_id = self.admission_phase_id
    else
      phases = [nil] + self.admission_process.phases.order(:order).map do |p|
        p.admission_phase.id
      end
      index = phases.find_index(self.admission_phase_id)
      set_phase_id = phases[index - 1]
    end
    self.pendencies.where(
      status: Admissions::AdmissionPendency::PENDENT,
      admission_phase_id: self.admission_phase_id
    ).delete_all
    self.update!(
      admission_phase_id: set_phase_id,
      status: nil,
      status_message: nil,
    )
    if set_phase_id.present?
      self.results.where(
        mode: Admissions::AdmissionPhaseResult::CONSOLIDATION,
        admission_phase_id: set_phase_id
      ).delete_all
      prev_phase = Admissions::AdmissionPhase.find(set_phase_id)
      prev_phase.update_pendencies
      prev_phase_name = prev_phase.name
    else
      prev_phase_name = "Candidatura"
    end
    prev_phase_name
  end

  def phase_name
    self.admission_phase.try(:name)
  end

  def identifier
    self.token[..5]
  end

  def can_edit_itself
    return true if self.admission_phase_id.nil?
    return false if !self.admission_phase.candidate_can_edit
    !END_OF_PHASE_STATUSES.include?(self.status)
  end

  def ordered_rankings
    self.rankings.joins(admission_application: { admission_process: :rankings })
      .where("
        `admission_process_rankings`.`ranking_config_id` =
        `admission_ranking_results`.`ranking_config_id`
      ")
      .order(Arel.sql("`admission_process_rankings`.`order` ASC"))
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
