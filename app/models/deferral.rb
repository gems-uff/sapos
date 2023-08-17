# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a Deferral for a Enrollment
class Deferral < ApplicationRecord
  include ::MonthYearConcern
  has_paper_trail

  belongs_to :enrollment, optional: false
  belongs_to :deferral_type, optional: false

  validates :enrollment, presence: true
  validates :enrollment, uniqueness: {
    scope: :deferral_type_id,
    message: :enrollment_and_deferral_uniqueness
  }
  validates :deferral_type, presence: true
  validates :approval_date, presence: true


  validate :that_deferral_type_levels_include_enrollment_level

  after_commit :recalculate_due_date_for_phase_completion
  after_create :notify_student_and_advisor

  month_year_date :approval_date

  def to_label
    "#{deferral_type.name}" unless deferral_type.blank?
  end

  def valid_until
    DateUtils.add_hash_to_date(
      enrollment.admission_date,
      deferral_type.phase.total_duration(enrollment, until_date: approval_date)
    ).strftime("%d/%m/%Y")
  end

  def recalculate_due_date_for_phase_completion
    phase_completion = PhaseCompletion.where(
      enrollment_id: enrollment_id, phase_id: deferral_type.phase_id
    ).first
    if phase_completion
      phase_completion.calculate_due_date
      phase_completion.save
    end
  end

  def that_deferral_type_levels_include_enrollment_level
    return if enrollment.blank?
    return if deferral_type.blank?
    return if deferral_type.phase.levels.include? enrollment.level

    errors.add(:enrollment, :enrollment_level)
  end

  def notify_student_and_advisor
    emails = [
      EmailTemplate.load_template(
        "deferrals:email_to_student"
      ).prepare_message({
        record: self
      })
    ]
    enrollment.advisements.each do |advisement|
      emails << EmailTemplate.load_template(
        "deferrals:email_to_advisor"
      ).prepare_message({
        record: self,
        advisement: advisement
      })
    end
    Notifier.send_emails(notifications: emails)
  end
end
