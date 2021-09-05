#encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class PhaseCompletion < ApplicationRecord

  belongs_to :enrollment
  belongs_to :phase

  validates :enrollment_id, :presence => true
  validates :phase_id, :presence => true
  validates :phase_id, :uniqueness => {:scope => :enrollment_id}

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
    return if enrollment.nil? or phase.nil? or !phase.phase_durations.any?

    self.calculate_due_date
    self.calculate_completion_date
  end

  def calculate_due_date
    return unless phase.phase_durations.where(:level_id => enrollment.level_id).any?
    self.due_date = DateUtils.add_hash_to_date(
      enrollment.admission_date,
      phase.total_duration(enrollment)
    )
  end

  def calculate_completion_date
    phase_accomplishment = self.phase_accomplishment
    self.completion_date = nil
    self.completion_date = phase_accomplishment.conclusion_date unless phase_accomplishment.nil?
  end

  def phase_accomplishment
    self.enrollment.accomplishments.where(:phase_id => phase.id)[0]
  end
  

end
