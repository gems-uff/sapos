# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Assertion < ApplicationRecord
  has_paper_trail

  @@disable_erb_validation = false
  LIQUID = record_i18n_attr("template_types.liquid")
  ERB = record_i18n_attr("template_types.erb")

  TEMPLATE_TYPES = [LIQUID, ERB]

  attr_accessor :args
  belongs_to :query, inverse_of: :assertions, optional: false

  validates :name, presence: true
  validates :assertion_template, presence: true, on: :update
  validates :expiration_in_months, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :template_type, presence: true, inclusion: { in: TEMPLATE_TYPES }, allow_blank: false
  validate :only_student_enrollment_param, if: -> { self.student_can_generate }
  validate :cannot_create_new_erb_template, if: -> { self.template_type == ERB } 

  scope :student_allowed, -> { where(student_can_generate: true) }

  def to_label
    "#{self.name}"
  end

  def self.disable_erb_validation!
    @@disable_erb_validation = true
    yield
    @@disable_erb_validation = false
  end

  private
    def only_student_enrollment_param
      if self.query.params.pluck(:name) != ["matricula_aluno"]
        errors.add(:student_can_generate, :default_enrollment_variable_required)
      end
    end

    def cannot_create_new_erb_template
      return if @@disable_erb_validation
      assertion = self.paper_trail.previous_version
      current = I18n.transliterate(self.assertion_template).downcase
      while assertion.present?
        old = I18n.transliterate(assertion.assertion_template).downcase
        if current == old && assertion.template_type == ERB
          return
        end
        assertion = assertion.paper_trail.previous_version
      end
      errors.add(:assertion_template, :cannot_create_new_erb_template)
    end
end
