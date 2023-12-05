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
    NEQ => ->(f, v) { f.to_f != v.to_f },
    NULL => ->(f, v) { f.nil? },
    NOT_NULL => ->(f, v) { !f.nil? },
  }

  def to_label
    "#{self.field} #{self.condition} #{self.value}"
  end
end
