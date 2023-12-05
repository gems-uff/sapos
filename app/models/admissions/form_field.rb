# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FormField < ActiveRecord::Base
  has_paper_trail

  HTML = record_i18n_attr("field_types.html")
  STRING = record_i18n_attr("field_types.string")
  NUMBER = record_i18n_attr("field_types.number")
  SELECT = record_i18n_attr("field_types.select")
  RADIO = record_i18n_attr("field_types.radio")
  COLLECTION_CHECKBOX = record_i18n_attr("field_types.collection_checkbox")
  SINGLE_CHECKBOX = record_i18n_attr("field_types.single_checkbox")
  STUDENT_FIELD = record_i18n_attr("field_types.student_field")
  FILE = record_i18n_attr("field_types.file")
  TEXT = record_i18n_attr("field_types.text")
  CITY = record_i18n_attr("field_types.city")
  GROUP = record_i18n_attr("field_types.group")
  SCHOLARITY = record_i18n_attr("field_types.scholarity")
  RESIDENCY = record_i18n_attr("field_types.residency")

  SEP = record_i18n_attr("field_types.sep")

  CODE = record_i18n_attr("field_types.code")

  FIELD_TYPES = [
    FILE, STUDENT_FIELD, COLLECTION_CHECKBOX, SINGLE_CHECKBOX,
    CITY, SCHOLARITY, GROUP, HTML, NUMBER, RESIDENCY,
    RADIO, SELECT, STRING, TEXT, SEP, CODE
  ]

  SYNC_NAME = record_i18n_attr("syncs.name")
  SYNC_EMAIL = record_i18n_attr("syncs.email")
  SYNC_TELEPHONE = record_i18n_attr("syncs.telephone")
  SYNCS = [SYNC_NAME, SYNC_EMAIL, SYNC_TELEPHONE]
  SYNCS_APPLICATION = [SYNC_NAME, SYNC_EMAIL]
  SYNCS_MAP = {
    SYNC_NAME => :name,
    SYNC_EMAIL => :email,
    SYNC_TELEPHONE => :telephone
  }

  has_many :filled_fields, dependent: :restrict_with_exception,
    class_name: "Admissions::FilledFormField"

  belongs_to :form_template, optional: false,
    class_name: "Admissions::FormTemplate"

  validates :field_type, presence: true
  validates :form_template, presence: true
  validates :sync, uniqueness: { scope: :form_template_id, allow_blank: true }
  validates :sync, inclusion: { in: SYNCS, allow_blank: true },
    if: ->(field) {
      field.try(:form_template).try(:template_type) ==
        Admissions::FormTemplate::RECOMMENDATION_LETTER
    }
  validates :sync, inclusion: { in: SYNCS_APPLICATION, allow_blank: true },
    if: ->(field) {
      field.try(:form_template).try(:template_type) ==
        Admissions::FormTemplate::ADMISSION_FORM
    }
  validates :field_type, inclusion: { in: FIELD_TYPES - [SEP, CODE] },
    if: ->(field) {
      template_type = field.try(:form_template).try(:template_type)
      template_type == Admissions::FormTemplate::ADMISSION_FORM ||
        Admissions::FormTemplate::RECOMMENDATION_LETTER
    }
  validates :field_type, inclusion: { in: [CODE] },
    if: ->(field) {
      field.try(:form_template).try(:template_type) ==
        Admissions::FormTemplate::CONSOLIDATION_FORM
    }

  validates :name, presence: true
  validate :that_configuration_is_valid

  def that_configuration_is_valid
    config = JSON.parse(self.configuration || "{}")
  rescue JSON::ParserError, TypeError
    self.errors.add(:configuration, :invalid_format)
  else
    case self.field_type
    when Admissions::FormField::SELECT
      validate_values_sql(config, "values")
    when Admissions::FormField::RADIO
      validate_values_sql(config, "values")
    when Admissions::FormField::COLLECTION_CHECKBOX
      validate_values_sql(config, "values")
      validate_values_sql(config, "default_values", check_presence: false)
      validate_selection_count(config)
    when Admissions::FormField::STUDENT_FIELD
      validate_presence(config, "field")
      return if config["field"].blank?
      if config["field"] == "special_majors"
        validate_scholarity(config)
      end
    when Admissions::FormField::SCHOLARITY
      validate_scholarity(config)
    end
  end

  def validate_scholarity(config)
    validate_values_sql(config, "values")
    validate_values_sql(config, "statuses")
  end

  def validate_values(config, field, check_presence: true)
    if check_presence && config[field].blank?
      self.errors.add(:base, :"#{field}_present_error")
    elsif config[field].present? && config[field].any? { |x| x.strip == "" }
      self.errors.add(:base, :"#{field}_blank_error")
    end
  end

  def validate_values_sql(config, field, check_presence: true)
    if config["#{field}_use_sql"].present?
      field_name = "#{field}_sql"
      validate_presence(config, field_name) if check_presence
      begin
        self.execute_sql(field, config: config)
      rescue Exception => e
        self.errors.add(:base, :sql_execution_generated_an_error,
          field: record_i18n_attr("configurations.#{field_name}"),
          error: e.message
        )
      end
    else
      validate_values(config, field, check_presence: check_presence)
    end
  end

  def validate_selection_count(config)
    minselection = config["minselection"].to_i
    maxselection = config["maxselection"].to_i
    if maxselection != 0 && minselection > maxselection
      self.errors.add(:base, :selection_count_error)
    end
  end

  def validate_presence(config, field)
    if config[field].blank?
      self.errors.add(:base, :"#{field}_present_error")
    end
  end

  def execute_sql(option, config: nil)
    return [] if config["#{option}_sql"].blank?
    config = JSON.parse(self.configuration || "{}") if config.nil?
    generated_query = ::Query.parse_sql_and_params(config["#{option}_sql"], {})
    db_resource = ::Query.run_read_only_query(generated_query)
    (db_resource[:rows] || []).collect { |x| x[0..1].map(&:to_s) }
  end

  def get_values(option)
    config = JSON.parse(self.configuration || "{}")
  rescue JSON::ParserError, TypeError
    []
  else
    return (config[option] || []) if config["#{option}_use_sql"].blank?
    execute_sql(option, config: config)
  end

  def get_values_map(option)
    values = self.get_values(option)
    result = {}
    values.each do |value|
      if value.kind_of?(Array)
        result[value.last] = value.first
      else
        result[value] = value
      end
    end
    result
  end
end
