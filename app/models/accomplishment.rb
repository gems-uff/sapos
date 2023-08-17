# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents an Accomplishment of a Phase by an Enrollment
class Accomplishment < ApplicationRecord
  include ::MonthYearConcern
  has_paper_trail

  belongs_to :enrollment, optional: false
  belongs_to :phase, optional: false

  validates :enrollment, presence: true
  validates :enrollment, uniqueness: {
    scope: :phase_id, message: :accomplishment_enrollment_uniqueness
  }
  validates :phase, presence: true

  validates :conclusion_date, presence: true
  validate :that_phase_levels_include_enrollment_level

  after_commit :update_completion_date
  after_create :notify_student_and_advisor

  month_year_date :conclusion_date

  def to_label
    "#{phase.name}"
  end

  def update_completion_date
    phase_completion = PhaseCompletion.where(
      enrollment_id: enrollment_id, phase_id: phase_id
    ).first
    return unless phase_completion

    phase_completion.calculate_completion_date
    phase_completion.save
  end

  def that_phase_levels_include_enrollment_level
    return if enrollment.blank?
    return if phase.blank?
    return if phase.levels.include? enrollment.level

    errors.add(:enrollment, :enrollment_level)
  end

  def notify_student_and_advisor
    emails = [
      EmailTemplate.load_template(
        "accomplishments:email_to_student"
      ).prepare_message({ record: self })]
    enrollment.advisements.each do |advisement|
      emails << EmailTemplate.load_template(
        "accomplishments:email_to_advisor"
      ).prepare_message({
        record: self,
        advisement: advisement
      })
    end
    Notifier.send_emails(notifications: emails)
  end
end
