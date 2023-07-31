# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents an Advisement of a student Enrollment by a Professor
class Advisement < ApplicationRecord
  has_paper_trail

  belongs_to :professor, optional: false
  belongs_to :enrollment, optional: false

  validates :professor, presence: true
  validates :enrollment, presence: true

  # A professor can't be advisor more than once of an enrollment
  validates :professor, uniqueness: {
    scope: :enrollment_id,
    message: :advisement_professor_uniqueness
  }

  after_create :notify_advisor

  def to_label
    "#{enrollment.enrollment_number} - #{professor.name}"
  end

  # defines if an certain advisement is active (An active advisement is an advisement which the student doesn't have a dismissal reason
  def active
    return false if enrollment.blank?
    dismissals = Dismissal.where(enrollment_id: enrollment.id)
    dismissals.empty?
  end

  def active_order
    active.to_s
  end

  def co_advisor_list
    return "" if enrollment.blank?
    return "" if professor.blank?
    professor_list = Professor.
                     joins(:advisements).
                     order("professors.name").
                     where("advisements.enrollment_id" => enrollment.id).
                     where("professors.id <> ? ", professor.id)

    professor_list.map(&:name).join(" , ")
  end

  def co_advisor
    return false if enrollment.blank?
    co_advisors = Advisement.where(main_advisor: false, enrollment_id: enrollment.id)
    !co_advisors.empty?
  end

  def co_advisor_order
    co_advisor.to_s
  end

  def enrollment_number
    return nil if enrollment.blank?
    enrollment.enrollment_number
  end

  def student_name
    return nil if enrollment.blank?
    return nil if enrollment.student.blank?
    enrollment.student.name
  end

  def enrollment_has_advisors
    return false if enrollment.blank?
    enrollment_advisements = Advisement.where(enrollment_id: enrollment.id)
    return false if enrollment_advisements.empty?
    !enrollment_advisements.where(main_advisor: true).empty?
  end

  def notify_advisor
    emails = [EmailTemplate.load_template("advisements:email_to_advisor").prepare_message({
      record: self
    })]
    Notifier.send_emails(notifications: emails)
  end
end
