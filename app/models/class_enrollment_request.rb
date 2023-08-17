# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a student EnrollmentRequest for a specific CourseClass
class ClassEnrollmentRequest < ApplicationRecord
  has_paper_trail

  attr_accessor :student_saving, :db_status, :db_action

  belongs_to :enrollment_request,
    inverse_of: :class_enrollment_requests, optional: false
  belongs_to :course_class, optional: false
  belongs_to :class_enrollment, optional: true

  has_one :enrollment, through: :enrollment_request

  REQUESTED = I18n.translate(
    "activerecord.attributes.class_enrollment_request.statuses.requested"
  )
  VALID = I18n.translate(
    "activerecord.attributes.class_enrollment_request.statuses.valid"
  )
  INVALID = I18n.translate(
    "activerecord.attributes.class_enrollment_request.statuses.invalid"
  )
  EFFECTED = I18n.translate(
    "activerecord.attributes.class_enrollment_request.statuses.effected"
  )
  STATUSES = [INVALID, REQUESTED, VALID, EFFECTED]
  STATUSES_MAP = {
    INVALID => :invalid,
    REQUESTED => :requested,
    VALID => :valid,
    EFFECTED => :effected
  }

  INSERT = I18n.translate(
    "activerecord.attributes.class_enrollment_request.actions.insert"
  )
  REMOVE = I18n.translate(
    "activerecord.attributes.class_enrollment_request.actions.remove"
  )
  ACTIONS = [INSERT, REMOVE]

  validates :enrollment_request, presence: true
  validates :course_class, presence: true
  validates_uniqueness_of :course_class,
    scope: [:enrollment_request_id], if: -> { !student_saving }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :class_enrollment,
    presence: true, if: -> { status == EFFECTED && action == INSERT }

  # The before_validation :create_or_destroy_class_enrollment makes it always valid
  # validates :class_enrollment,
  #   presence: false, if: -> { status == EFFECTED && action == REMOVE }

  validate :that_class_enrollment_matches_course_and_enrollment,
    if: -> { !student_saving && !marked_for_destruction? }
  validate :that_course_class_does_not_exist_in_a_class_enrollment,
    if: -> { !marked_for_destruction? }

  before_validation :create_or_destroy_class_enrollment, on: %i[create update]
  after_save :destroy_or_create_class_enrollment
  after_save :set_db_status
  after_initialize :set_db_status

  def self.pendency_condition(user = nil)
    user ||= current_user
    return ["0 = -1"] if user.blank?
    return ["0 = -1"] if user.cannot?(:read_pendencies, ClassEnrollmentRequest)

    cer = ClassEnrollmentRequest.arel_table.dup
    cer.table_alias = "cer"
    check_status = cer.where(
      cer[:status].not_eq(ClassEnrollmentRequest::EFFECTED)
      .and(cer[:status].not_eq(ClassEnrollmentRequest::INVALID))
    )

    [
      ClassEnrollmentRequest.arel_table[:id].in(
        check_status.project(cer[:id])
      ).to_sql
    ]
  end

  def allocations
    return "" unless course_class = self.course_class
    course_class.allocations.collect do |allocation|
      "#{allocation.day} (#{allocation.start_time}-#{allocation.end_time})"
    end.join("; ")
  end

  def professor
    return nil unless course_class = self.course_class
    course_class.professor.to_label if course_class.professor
  end

  def set_status!(new_status)
    changed = new_status != status ||
      (new_status == EFFECTED && action == INSERT && class_enrollment.blank?) ||
      (new_status == EFFECTED && action == REMOVE && class_enrollment.present?)
    self.status = new_status
    changed && save
  end

  def insert_effected?
    self.action == ClassEnrollmentRequest::INSERT &&
    self.status == ClassEnrollmentRequest::EFFECTED
  end

  def insert_not_effected?
    self.action == ClassEnrollmentRequest::INSERT &&
    self.status != ClassEnrollmentRequest::EFFECTED
  end

  def remove_effected?
    self.action == ClassEnrollmentRequest::REMOVE &&
    self.status == ClassEnrollmentRequest::EFFECTED
  end

  def remove_not_effected?
    self.action == ClassEnrollmentRequest::REMOVE &&
    self.status != ClassEnrollmentRequest::EFFECTED
  end

  protected
    def that_class_enrollment_matches_course_and_enrollment
      ce = self.class_enrollment
      return if ce.blank?
      return if ce.course_class_id == self.course_class_id &&
        ce.enrollment_id == self.enrollment_request.enrollment_id

      errors.add(
        :class_enrollment, :must_represent_the_same_enrollment_and_class
      )
    end

    def that_course_class_does_not_exist_in_a_class_enrollment
      return if action != INSERT
      return if enrollment_request.blank? || course_class.blank?
      enrollment = self.enrollment_request.enrollment
      return if enrollment.blank?

      course = course_class.course
      return if enrollment.class_enrollments.none? do |enrollment_class|
        enrollment_class.course_class.course_id == course.id &&
          enrollment_class != class_enrollment &&
          !course.course_type.allow_multiple_classes &&
          enrollment_class.situation != ClassEnrollment::DISAPPROVED
      end

      errors.add(:course_class, :previously_approved)
    end

    def create_or_destroy_class_enrollment
      return if status != EFFECTED

      if action == INSERT && class_enrollment.blank?
        self.class_enrollment = ClassEnrollment.new(
          enrollment: enrollment_request.enrollment,
          course_class: course_class,
          situation: ClassEnrollment::REGISTERED
        )
      end
      removing_class_enrollment = (
        action == REMOVE &&
        class_enrollment.present? && class_enrollment.can_destroy?
      )
      if removing_class_enrollment
        class_enrollment.destroy!
      end
    end

    def destroy_or_create_class_enrollment
      return if self.status == EFFECTED

      inserting_removal = (
        action == INSERT &&
        class_enrollment.present? && class_enrollment.can_destroy?
      )
      if inserting_removal
        old_status = status
        class_enrollment.destroy
        self.status = old_status
        self.class_enrollment = nil
        save
      end
      if action == REMOVE && class_enrollment.blank?
        self.class_enrollment = ClassEnrollment.new(
          enrollment: enrollment_request.enrollment,
          course_class: course_class,
          situation: ClassEnrollment::REGISTERED
        )
        save
      end
    end

    def set_db_status
      self.db_status = status
      self.db_action = action
    end
end
