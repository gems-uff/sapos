# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a hold of an Enrollment
class EnrollmentHold < ApplicationRecord
  has_paper_trail

  belongs_to :enrollment, optional: false

  validates :enrollment, presence: true
  validates :number_of_semesters,
    numericality: { greater_than_or_equal_to: 1 }, presence: true
  validates :semester, inclusion: [1, 2], presence: true
  validates :year, presence: true

  validate :validate_dates
  validate :cancel_class_enrollments

  after_commit :create_phase_completions

  def to_label
    "#{date_label} - #{number_label}"
  end

  def date_label
    "#{year}.#{semester}"
  end

  def number_label
    I18n.t(
      "activerecord.attributes.enrollment_hold.number_label",
      count: number_of_semesters
    )
  end

  def validate_dates
    return if enrollment.blank? || year.nil? || semester.nil?
    admission_date = enrollment.admission_date
    if self.start_date < admission_date
      errors.add(:base, :before_admission_date)
    end
    dismissal = enrollment.dismissal
    if dismissal.present? && dismissal.dismissal_reason.thesis_judgement == DismissalReason::APPROVED
      if self.end_date > dismissal.date
        errors.add(:base, :after_dismissal_date)
      end
    end
  end

  def start_date
    ys = YearSemester.new(year: year, semester: semester)
    ys.semester_begin
  end

  def end_date
    ys = YearSemester.new(year: year, semester: semester)
    (ys + (number_of_semesters - 1)).semester_end
  end

  def create_phase_completions
    enrollment.create_phase_completions
  end

  def cancel_class_enrollments
    class_enrollments = ClassEnrollment.where(enrollment: self.enrollment)
    class_enrollments.each do |class_enrollment|
      course_class = class_enrollment.course_class
      unless course_class.end_date < self.start_date || course_class.start_date > self.end_date
        class_enrollment.delete
      end
    end
  end
end
