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

  validate :enrollment_has_main_advisor
  validate :enrollment_has_authorized_advisor
  validate :verify_research_area_with_advisors

  after_create :notify_advisor

  def to_label
    "#{enrollment.enrollment_number} - #{professor.name}"
  end

  # defines if an certain advisement is active (An active advisement is
  # an advisement which the student doesn't have a dismissal reason
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
    co_advisors = Advisement.where(
      main_advisor: false, enrollment_id: enrollment.id
    )
    co_advisors.present?
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

  def enrollment_has_main_advisor
    return if enrollment.blank?
    advisements = enrollment.advisements.reject(&:marked_for_destruction?)

    advisements = advisements.map { |a| a.id == self.id ? self : a }

    advisements << self if new_record? && advisements.exclude?(self)

    return if advisements.blank? && main_advisor

    main_advisors = advisements.count(&:main_advisor)
    errors.add(:base, :main_advisor_required) if main_advisors == 0
    errors.add(:base, :main_advisor_uniqueness) if main_advisors > 1
  end

  def enrollment_has_authorized_advisor
    return unless CustomVariable.enable_advisor_accreditation_validation
    return if enrollment.blank? || enrollment.level.blank?
    return if professor.present? && professor.advisement_authorizations.any? { |auth| auth.level == enrollment.level }

    advisements = enrollment.advisements.reject(&:marked_for_destruction?)
    has_authorized = advisements.any? do |a|
      a.professor.present? &&
        a.professor.advisement_authorizations.any? { |auth| auth.level == enrollment.level }
    end

    errors.add(:base, :no_advisor_with_level) unless has_authorized
  end

  def verify_research_area_with_advisors
    return if enrollment.blank? || enrollment.research_area.blank?
    return if professor.research_areas.include?(enrollment.research_area)

    advisements = enrollment.advisements.reject(&:marked_for_destruction?)
    has_research_area = advisements.any? do |a|
      a.professor.research_areas.include?(enrollment.research_area)
    end

    errors.add(:base, :research_area_different_from_professors) unless has_research_area
  end

  def notify_advisor
    emails = [
      EmailTemplate.load_template(
        "advisements:email_to_advisor"
      ).prepare_message({
        record: self
      })
    ]
    Notifier.send_emails(notifications: emails)
  end

end
