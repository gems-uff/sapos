# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FormCondition < ActiveRecord::Base
  has_paper_trail

  belongs_to :parent, optional: true,
    class_name: "Admissions::FormCondition", foreign_key: :parent_id
  has_many :form_conditions, dependent: :destroy,
    class_name: "Admissions::FormCondition", foreign_key: :parent_id
  has_many :admission_phases_as_approval, dependent: :destroy,
    class_name: "Admissions::AdmissionPhase", foreign_key: :approval_condition_id
  has_many :admission_committees, dependent: :destroy,
    class_name: "Admissions::AdmissionCommittee"
  has_many :admission_report_configs, dependent: :destroy,
    class_name: "Admissions::AdmissionReportConfig"

  AND = record_i18n_attr("modes.and")
  OR = record_i18n_attr("modes.or")
  CONDITION = record_i18n_attr("modes.condition")
  NONE = record_i18n_attr("modes.none")
  MODES = [AND, OR, CONDITION, NONE]

  CONTAINS = record_i18n_attr("conditions.contains")
  STARTS_WITH = record_i18n_attr("conditions.starts_with")
  ENDS_WITH = record_i18n_attr("conditions.ends_with")
  EQUALS = record_i18n_attr("conditions.equals")
  GE = record_i18n_attr("conditions.ge")
  LE = record_i18n_attr("conditions.le")
  GT = record_i18n_attr("conditions.gt")
  LT = record_i18n_attr("conditions.lt")
  NEQ = record_i18n_attr("conditions.neq")
  NULL = record_i18n_attr("conditions.is_null")
  NOT_NULL = record_i18n_attr("conditions.not_null")

  OPTIONS = {
    CONTAINS => { values: 1 },
    STARTS_WITH => { values: 1 },
    ENDS_WITH => { values: 1 },
    EQUALS => { values: 1 },
    GE => { values: 1 },
    LE => { values: 1 },
    GT => { values: 1 },
    LT => { values: 1 },
    NEQ => { values: 1 },
    NULL => { values: 0 },
    NOT_NULL => { values: 0 },
  }

  RAISE_COMMITTEE = record_i18n_attr("raises.committee")
  RAISE_PHASE = record_i18n_attr("raises.phase")
  RAISE_FORM_FIELD = record_i18n_attr("raises.form_field")

  validates :mode, presence: true
  validates :field, presence: true, if: -> { mode == CONDITION }

  accepts_nested_attributes_for :form_conditions,
    reject_if: :all_blank,
    allow_destroy: true

  after_commit :update_pendencies

  def update_pendencies
    self.admission_committees.each do |committee|
      committee.update_pendencies
    end
    self.parent.update_pendencies if self.parent.present?
  end

  def to_label
    return "#{self.field} #{self.condition} #{self.value}" if self.mode == CONDITION
    sep = self.mode == AND ? " & " : " | "
    self.form_conditions.map{ |x| "(#{x.to_label})" }.join(sep)
  end

  def initialize_dup(other)
    super
    self.form_conditions = other.form_conditions.map(&:dup)
  end

  def compare(first, second, field)
    case self.condition
    when CONTAINS
      first.include? second
    when STARTS_WITH
      first.starts_with? second
    when ENDS_WITH
      first.ends_with? second
    when EQUALS
      first == second
    when NEQ
      first != second
    when GE
      type = field.get_type
      Admissions::FilledFormField.convert_value(first, type) >=
        Admissions::FilledFormField.convert_value(second, type)
    when LE
      type = field.get_type
      Admissions::FilledFormField.convert_value(first, type) <=
        Admissions::FilledFormField.convert_value(second, type)
    when GT
      type = field.get_type
      Admissions::FilledFormField.convert_value(first, type) >
        Admissions::FilledFormField.convert_value(second, type)
    when LT
      type = field.get_type
      Admissions::FilledFormField.convert_value(first, type) <
        Admissions::FilledFormField.convert_value(second, type)
    when NULL
      first.nil?
    when NOT_NULL
      !first.nil?
    else
      false
    end
  end

  def self.check_truth(condition, should_raise: nil, default: true, &block)
    return default if condition.nil?
    return default if condition.mode == NONE
    case condition.mode
    when AND
      condition.form_conditions.all? do |child|
        self.check_truth(child, should_raise: should_raise, &block)
      end
    when OR
      condition.form_conditions.any? do |child|
        self.check_truth(child, should_raise: should_raise, &block)
      end
    else
      field = yield condition.field
      if field.blank?
        raise MissingFieldException.new(I18n.t(
          "errors.admissions/admission_application.field_not_found",
          field: condition.field, source: should_raise
        )) if should_raise.present?
        return false
      end
      if field.file.present?
        condition.compare(field.file, condition.value, field)
      elsif field.list.present?
        field.list.any? do |element|
          condition.compare(element, condition.value, field)
        end
      else
        condition.compare(field.value, condition.value, field)
      end
    end
  end

  def self.new_from_hash(hash)
    return nil if hash.nil?
    form_conditions = hash["form_conditions"] || []
    condition = Admissions::FormCondition.new(hash.except("form_conditions"))
    form_conditions.each do |child|
      condition.form_conditions << self.new_from_hash(child)
    end
    condition
  end

  def to_hash
    result = {
      mode: self.mode,
      field: self.field,
      condition: self.condition,
      value: self.value,
      form_conditions: self.form_conditions.map(&:to_hash)
    }
    result[:id] = self.id if self.id.present?
    result
  end

  def widget
    self.to_label
  end
  def widget=(value)
  end

end

class MissingFieldException < StandardError
  def initialize(msg, exception_type = "missing_field")
    @exception_type = exception_type
    super(msg)
  end
end
