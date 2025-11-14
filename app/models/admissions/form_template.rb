# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FormTemplate < ActiveRecord::Base
  has_paper_trail

  ADMISSION_FORM = record_i18n_attr("template_types.admission_form")
  RECOMMENDATION_LETTER = record_i18n_attr("template_types.recommendation_letter")
  CONSOLIDATION_FORM = record_i18n_attr("template_types.consolidation_form")
  RANKING = record_i18n_attr("template_types.ranking")

  TEMPLATE_TYPES = [
    ADMISSION_FORM, RECOMMENDATION_LETTER, CONSOLIDATION_FORM, RANKING
  ]

  scope :consolidation, -> { where(template_type: CONSOLIDATION_FORM) }
  scope :input_form, -> {
    where(template_type: ADMISSION_FORM)
    .or(where(template_type: RECOMMENDATION_LETTER))
  }

  has_many :fields, dependent: :destroy,
    class_name: "Admissions::FormField"
  has_many :admission_process_forms, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionProcess",
    foreign_key: :form_template_id
  has_many :admission_process_letters, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionProcess",
    foreign_key: :letter_template_id
  has_many :phase_member_forms, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionPhase",
    foreign_key: :member_form_id
  has_many :phase_shared_forms, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionPhase",
    foreign_key: :shared_form_id
  has_many :phase_consolidation_forms, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionPhase",
    foreign_key: :consolidation_form_id
  has_one :ranking_config, dependent: :destroy,
    class_name: "Admissions::RankingConfig"
  has_many :admission_report_configs, dependent: :restrict_with_exception,
    class_name: "Admissions::AdmissionReportConfig",
    foreign_key: :form_template_id

  validates :name, presence: true
  validates :template_type, presence: true, inclusion: { in: TEMPLATE_TYPES }

  def initialize_dup(other)
    super
    self.fields = other.fields.map(&:dup)
  end

  def has_file_fields?
    fields.any? { |f| f.is_file_field? }
  end

  def self.sispos_sucupira_student_fields_config
    [
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.initial_text"),
        field_type: Admissions::FormField::HTML,
        configuration: JSON.dump({
          "html": I18n.t("active_scaffold.admissions/form_template.generate_fields.initial_text_html")
        }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.personal_data"),
        field_type: Admissions::FormField::GROUP },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.name"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        sync: Admissions::FormField::SYNC_NAME,
        configuration: JSON.dump({ "field": "name", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.birthdate"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "birthdate", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.birth_city"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({"field": "special_birth_city", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.humanitarian_policy"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "humanitarian_policy", "required": false }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.sex"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "sex", "required": false }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.gender"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "gender", "required": false }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.skin_color"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "skin_color", "required": false }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.deficiency"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "pcd", "required": false }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.identity_or_passport"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "identity_number", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.identity_issuing_body"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "identity_issuing_body", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.identity_issuing_place"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "identity_issuing_place", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.identity_expedition_date"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "identity_expedition_date", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.cpf"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "cpf", "required": false }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.civil_status"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "civil_status", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.mother_name"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "mother_name", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.father_name"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "father_name" }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.address_group"),
        field_type: Admissions::FormField::GROUP },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.city"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({
          "field": "special_city",
          "required": true
        }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.address"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "special_address", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.neighborhood"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "neighborhood", "required": false }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.zip_code"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "zip_code", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.contact"),
        field_type: Admissions::FormField::GROUP },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.cellphone"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "telephone1", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.telephone"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "telephone2" }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.email"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        sync: Admissions::FormField::SYNC_EMAIL,
        configuration: JSON.dump({ "field": "email", "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.scholarity"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        description: I18n.t("active_scaffold.admissions/form_template.generate_fields.scholarity_description"),
        configuration: JSON.dump({
          "field": "special_majors",
          "values": I18n.t("active_scaffold.admissions/form_template.generate_fields.scholarities").values,
          "statuses": I18n.t("active_scaffold.admissions/form_template.generate_fields.scholarity_statuses").values,
          "scholarity_grade_interval_description": I18n.t("active_scaffold.admissions/form_template.generate_fields.scholarity_grade_interval_description"),
        }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.job"),
        field_type: Admissions::FormField::GROUP },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.employer"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "employer" }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.job_position"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: JSON.dump({ "field": "job_position" }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.attachments"),
        field_type: Admissions::FormField::GROUP },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.photo"),
        field_type: Admissions::FormField::STUDENT_FIELD,
        description: I18n.t("active_scaffold.admissions/form_template.generate_fields.photo_description"),
        configuration: JSON.dump({ "field": "photo" }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.identity_photo"),
        field_type: Admissions::FormField::FILE,
        description: I18n.t("active_scaffold.admissions/form_template.generate_fields.identity_photo_description"),
        configuration: JSON.dump({ "required": true }) },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.transcript"),
        description: I18n.t("active_scaffold.admissions/form_template.generate_fields.transcript_description"),
        field_type: Admissions::FormField::FILE },
      { name: I18n.t("active_scaffold.admissions/form_template.generate_fields.grades_report"),
        field_type: Admissions::FormField::FILE,
        description: I18n.t("active_scaffold.admissions/form_template.generate_fields.grades_report_description"),
        configuration: JSON.dump({ "required": true }) },
    ]
  end
end
