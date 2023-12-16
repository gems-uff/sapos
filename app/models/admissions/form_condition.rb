# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::FormCondition < ActiveRecord::Base
  has_paper_trail

  belongs_to :model, polymorphic: true

  validates :field, presence: true

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
    CONTAINS => ->(f, v) { f.include? v },
    STARTS_WITH => ->(f, v) { f.starts_with? v },
    ENDS_WITH => ->(f, v) { f.ends_with? v },
    EQUALS => ->(f, v) { f == v },
    GE => ->(f, v) { f.to_f >= v.to_f },
    LE => ->(f, v) { f.to_f <= v.to_f },
    GT => ->(f, v) { f.to_f > v.to_f },
    LT => ->(f, v) { f.to_f < v.to_f },
    NEQ => ->(f, v) { f != v },
    NULL => ->(f, v) { f.nil? },
    NOT_NULL => ->(f, v) { !f.nil? },
  }

  RAISE_COMMITTEE = record_i18n_attr("raises.committee")
  RAISE_PHASE = record_i18n_attr("raises.phase")
  RAISE_FORM_FIELD = record_i18n_attr("raises.form_field")

  after_commit :update_pendencies

  def update_pendencies
    return if model_type != "Admissions::AdmissionCommitee"
    self.model.admission_phase_committees.each do |pc|
      pc.update_pendencies
    end
    old = previous_changes.try(:model).try(:[], 0)
    if old.present?
      old.admission_phase_committees.each do |pc|
        pc.update_pendencies
      end
    end
  end

  def to_label
    "#{self.field} #{self.condition} #{self.value}"
  end

  def self.check_conditions(form_conditions, should_raise: nil, &block)
    form_conditions.all? do |condition|
      field = yield condition
      if field.blank?
        raise MissingFieldException.new(I18n.t(
          "errors.admissions/admission_application.field_not_found",
          field: condition.field, source: should_raise
        )) if should_raise.present?
        next false
      end
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
end

class MissingFieldException < StandardError
  def initialize(msg, exception_type = "missing_field")
    @exception_type = exception_type
    super(msg)
  end
end
