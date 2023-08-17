# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents the ClassEnrollment of a student Enrollment in a Course Class
class ClassEnrollment < ApplicationRecord
  has_paper_trail

  belongs_to :course_class, optional: false
  belongs_to :enrollment, optional: false

  has_one :class_enrollment_request, dependent: :nullify

  REGISTERED = I18n.translate(
    "activerecord.attributes.class_enrollment.situations.registered"
  )
  APPROVED = I18n.translate(
    "activerecord.attributes.class_enrollment.situations.aproved"
  )
  DISAPPROVED = I18n.translate(
    "activerecord.attributes.class_enrollment.situations.disapproved"
  )
  SITUATIONS = [REGISTERED, APPROVED, DISAPPROVED]

  validates :enrollment, presence: true
  validates :course_class, presence: true
  validates :course_class, uniqueness: { scope: :enrollment_id }
  validates :situation, presence: true, inclusion: { in: SITUATIONS }
  validate :grade_for_situation
  validate :disapproved_by_absence_for_situation
  validate :check_multiple_class_enrollment_allowed
  validate :professor_changed_only_valid_fields,
    if: -> { current_user && (current_user.role_id == Role::ROLE_PROFESSOR) }

  after_save :notify_student_and_advisor
  after_save :class_enrollment_request_cascade
  after_destroy :set_request_status_after_destroy

  default_scope {
    joins(enrollment: :student).order("students.name").readonly(false)
  }

  def check_multiple_class_enrollment_allowed
    return if self.course_class.blank?
    other_class_enrollments = ClassEnrollment
      .joins(course_class: { course: :course_type })
      .includes(course_class: { course: :course_type })
      .where(CourseType.arel_table[:allow_multiple_classes].eq(false))
      .where(enrollment_id: self.enrollment_id)
      .where(ClassEnrollment.arel_table[:situation].not_eq(DISAPPROVED))
      .where(Course.arel_table[:id].eq(self.course_class.course_id))
      .where.not(id: self.id)
      .where.not((self.situation == DISAPPROVED) ? "1" : "0")
      .group(:enrollment_id)
      .having("count(course_id) > 0")

    return if other_class_enrollments.empty?
    self.errors.add(:course_class, :multiple_class_enrollments_not_allowed)
  end

  def to_label
    "#{self.enrollment.student.name} - #{self.course_class.name_with_class}"
  end

  def attendance_to_label
    return if self.disapproved_by_absence.nil?
    return if self.situation == REGISTERED

    if self.disapproved_by_absence
      I18n.t("pdf_content.course_class.summary.attendance_false")
    else
      I18n.t("pdf_content.course_class.summary.attendance_true")
    end
  end

  def grade_filled?
    !grade.nil?
  end

  def grade_label(show = true)
    result = ""
    if grade_not_count_in_gpr.present?
      result = "*"
    elsif !course_has_grade
      result = "--"
    else
      show = true
    end
    result = "#{(grade / 10.0).round(2)}#{result}" if show && grade.present?
    result
  end

  def course_has_grade
    if self.try(:course_class).try(:course).try(:course_type).blank?
      true
    else
      self.course_class.course.course_type.has_score
    end
  end

  def grade=(new_grade)
    if new_grade.is_a?(String) && !new_grade.blank?
      split = new_grade.split(/[,.]/)
      # convert the float to grade integer
      # ex: if new_grade is 9.0, it will be converted to 90
      new_grade = split[0].to_i * 10 + split[1].to_i
    end
    super(new_grade)
  end

  def grade_to_view
    grade.nil? ? nil : (grade / 10.0)
  end

  def disapproved_by_absence_to_view
    self.disapproved_by_absence.nil? ? false : self.disapproved_by_absence
  end

  def should_send_email_to_professor?
    (!self.id.nil?) &&
    (
      self.will_save_change_to_grade? ||
      self.will_save_change_to_situation? ||
      self.will_save_change_to_disapproved_by_absence?
    )
  end

  private
    def grade_for_situation
      if course_has_grade
        unless self.grade.blank?
          self.errors.add(:grade, :grade_gt_100) if self.grade > 100
          self.errors.add(:grade, :grade_lt_0) if self.grade < 0
        end
        minimum = CustomVariable.minimum_grade_for_approval
        case self.situation
        when REGISTERED
          self.errors.add(
            :grade, :grade_for_situation_registered
          ) if self.grade.present?
        when APPROVED
          self.errors.add(
            :grade, :grade_for_situation_aproved,
            minimum_grade_for_approval: (minimum.to_f / 10.0).to_s.tr(".", ",")
          ) if (
            self.grade.blank? || self.grade < minimum
          ) && grade_not_count_in_gpr.blank?
        when DISAPPROVED
          self.errors.add(
            :grade, :grade_for_situation_disapproved,
            minimum_grade_for_approval: (minimum.to_f / 10.0).to_s.tr(".", ",")
          ) if (
            self.grade.blank? || self.grade >= minimum
          ) && grade_not_count_in_gpr.blank?
        end
      else
        self.errors.add(
          :grade, :grade_filled_for_course_without_score
        ) if self.grade.present?
      end
      self.errors.blank?
    end

    def disapproved_by_absence_for_situation
      grade_of_disapproval = CustomVariable.grade_of_disapproval_for_absence
      case self.situation
      when REGISTERED
        self.errors.add(
          :disapproved_by_absence,
          :disapproved_by_absence_for_situation_registered
        ) if self.disapproved_by_absence
      when APPROVED
        self.errors.add(
          :disapproved_by_absence,
          :disapproved_by_absence_for_situation_aproved
        ) if self.disapproved_by_absence
      when DISAPPROVED
        self.errors.add(
          :disapproved_by_absence,
          :disapproved_by_absence_for_situation_disapproved,
          grade_of_disapproval_for_absence: (
            grade_of_disapproval.to_f / 10.0
          ).to_s.tr(".", ",")
        ) if self.disapproved_by_absence &&
          course_has_grade &&
          grade_of_disapproval.present? &&
          ((self.grade.blank?) || (self.grade > grade_of_disapproval))
      end
      self.errors.blank?
    end

    def notify_student_and_advisor
      return if grade.nil?
      return if !(
        saved_change_to_grade? ||
        saved_change_to_situation? ||
        saved_change_to_disapproved_by_absence?
      )
      emails = [
        EmailTemplate.load_template(
          "class_enrollments:email_to_student"
        ).prepare_message({
          record: self
        })
      ]
      enrollment.advisements.each do |advisement|
        emails << EmailTemplate.load_template(
          "class_enrollments:email_to_advisor"
        ).prepare_message({
          record: self,
          advisement: advisement
        })
      end
      Notifier.send_emails(notifications: emails)
    end

    def professor_changed_only_valid_fields
      campos_modificaveis = [
        "grade", "situation", "disapproved_by_absence", "obs"
      ]
      campos_modificados  = self.changed

      campos_modificados.each do |campo_modificado|
        next if campos_modificaveis.include?(campo_modificado)
        next if (campo_modificado == "justification_grade_not_count_in_gpr") &&
          (justification_grade_not_count_in_gpr_change == ["", nil])

        errors.add(:class_enrollment, I18n.t(:changes_to_disallowed_fields))
        break
      end
    end

    def set_request_status_after_destroy
      request = self.class_enrollment_request
      unless request.blank?
        request.class_enrollment = nil
        request.status = ClassEnrollmentRequest::INVALID if
          request.action == ClassEnrollmentRequest::INSERT
        request.status = ClassEnrollmentRequest::EFFECTED if
          request.action == ClassEnrollmentRequest::REMOVE
        request.save
      end
    end

    def class_enrollment_request_cascade
      if saved_change_to_attribute?(:course_class_id)
        request = self.class_enrollment_request
        unless request.blank?
          request.course_class = self.course_class
          request.save
        end
      end
      if saved_change_to_attribute?(:enrollment_id)
        request = self.class_enrollment_request
        changed_enrollment = (
          request.present? &&
          request.enrollment_request.enrollment != self.enrollment
        )
        if changed_enrollment
          request.class_enrollment = nil
          request.status = ClassEnrollmentRequest::REQUESTED
          request.save
        end
      end
    end
end
