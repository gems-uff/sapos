# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a Phase completion for an Enrollment
class PhaseCompletion < ApplicationRecord
  belongs_to :enrollment, optional: false
  belongs_to :phase, optional: false

  validates :enrollment, presence: true
  validates :phase, presence: true
  validates :phase, uniqueness: { scope: :enrollment_id }

  after_initialize :init

  # callbacks that calculate dates:
  # accomplishment:
  # => after_commit   update_completion_date [completion_date]
  # deferral:
  # => after_commit   recalculate_due_date_for_phase_completion [due_date]
  # enrollment:
  # => after_save     create_phase_completions [due_date, completion_date]
  # enrollment_hold:
  # => after_commit   create_phase_completions [due_date, completion_date]
  # phase:
  # => after_save     create_phase_completions [due_date, completion_date]
  # phase_duration:
  # => after_save     create_phase_completions [due_date, completion_date]

  def init
    return if enrollment.blank? || phase.blank? || !phase.phase_durations.any?

    self.calculate_due_date
    self.calculate_completion_date
  end

  def calculate_due_date
    return if phase.phase_durations.where(level_id: enrollment.level_id).none?
    self.due_date = DateUtils.add_hash_to_date(
      enrollment.admission_date,
      phase.total_duration(enrollment)
    )
  end

  def calculate_completion_date
    phase_accomplishment = self.phase_accomplishment
    self.completion_date = nil
    return if phase_accomplishment.blank?
    self.completion_date = phase_accomplishment.conclusion_date
  end

  def phase_accomplishment
    self.enrollment.accomplishments.where(phase_id: phase.id)[0]
  end
end
