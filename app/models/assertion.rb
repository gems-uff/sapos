# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Assertion < ApplicationRecord
  has_paper_trail

  attr_accessor :args
  belongs_to :query, inverse_of: :assertions, optional: false

  validates :name, presence: true
  validates :assertion_template, presence: true, on: :update
  validate :only_student_enrollment_param, if: -> { self.student_can_generate }
  validates :expiration_in_months, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  scope :student_allowed, -> { where(student_can_generate: true) }

  def to_label
    "#{self.name}"
  end

  private
    def only_student_enrollment_param
      if self.query.params.pluck(:name) != ["matricula_aluno"]
        errors.add(:student_can_generate, :default_enrollment_variable_required)
      end
    end
end
