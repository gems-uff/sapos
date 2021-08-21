# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ClassEnrollment < ApplicationRecord
  belongs_to :course_class
  belongs_to :enrollment

  has_one  :class_enrollment_request, dependent: :nullify

  has_paper_trail

  REGISTERED = I18n.translate("activerecord.attributes.class_enrollment.situations.registered")
  APPROVED = I18n.translate("activerecord.attributes.class_enrollment.situations.aproved")
  DISAPPROVED = I18n.translate("activerecord.attributes.class_enrollment.situations.disapproved")
  SITUATIONS = [REGISTERED, APPROVED, DISAPPROVED]

  validates :enrollment, :presence => true
  validates :course_class, :presence => true
  validates :course_class_id, :uniqueness => {:scope => :enrollment_id}
  validates :situation, :presence => true, :inclusion => {:in => SITUATIONS}
  validate :grade_for_situation
  validate :disapproved_by_absence_for_situation
  validate :check_multiple_class_enrollment_allowed
  validate :professor_changed_only_valid_fields, if: -> {current_user && (current_user.role_id == Role::ROLE_PROFESSOR)}

  after_save :notify_student_and_advisor
  after_destroy :set_request_status

  default_scope {joins(:enrollment => :student).order('students.name').readonly(false)}

  def check_multiple_class_enrollment_allowed
    return if not self.course_class
      other_class_enrollments = ClassEnrollment.
          joins(:course_class => {:course => :course_type}).
          includes(:course_class => {:course => :course_type}).
          where(CourseType.arel_table[:allow_multiple_classes].eq(false)).
          where(:enrollment_id => self.enrollment_id).
          where(ClassEnrollment.arel_table[:situation].not_eq(DISAPPROVED)).
          where(Course.arel_table[:id].eq( self.course_class.course_id)).
          where.not(:id => self.id).
	  where.not((self.situation == I18n.translate("activerecord.attributes.class_enrollment.situations.disapproved"))? "1" : "0").
          group(:enrollment_id).
          having("count(course_id) > 0")

      unless other_class_enrollments.empty?
        self.errors.add(:course_class, :multiple_class_enrollments_not_allowed)
      end
    end

  def to_label
    "#{self.enrollment.student.name} - #{self.course_class.name_with_class}"
  end

  def attendance_to_label
    unless self.disapproved_by_absence.nil? || self.situation == I18n.t("activerecord.attributes.class_enrollment.situations.registered")
      self.disapproved_by_absence ? I18n.t("pdf_content.course_class.summary.attendance_false") : I18n.t("pdf_content.course_class.summary.attendance_true")
    end
  end

  def grade_filled?
    !grade.nil?
  end

  def course_has_grade
    if self.try(:course_class).try(:course).try(:course_type).nil?
      true
    else
      self.course_class.course.course_type.has_score
    end
  end

  def grade=(new_grade)
    if new_grade.is_a?(String) && !new_grade.blank?
      split = new_grade.split(/[,.]/)
      #convert the float to grade integer
      #ex: if new_grade is 9.0, it will be converted to 90
      new_grade = split[0].to_i*10 + split[1].to_i
    end
    super(new_grade)
  end

  def grade_to_view
    grade.nil? ? nil : (grade/10.0)
  end

  def disapproved_by_absence_to_view
    self.disapproved_by_absence.nil? ? false : self.disapproved_by_absence 
  end

  def should_send_email_to_professor?
    (!self.id.nil?) and 
    (
      self.will_save_change_to_grade? or
      self.will_save_change_to_situation? or
      self.will_save_change_to_disapproved_by_absence?
    )
  end

  private
  def grade_for_situation
    if course_has_grade
      unless self.grade.blank?
        self.errors.add(:grade, I18n.translate("activerecord.errors.models.class_enrollment.grade_gt_100")) if self.grade > 100
        self.errors.add(:grade, I18n.translate("activerecord.errors.models.class_enrollment.grade_lt_0")) if self.grade < 0
      end
      case self.situation
        when I18n.translate("activerecord.attributes.class_enrollment.situations.registered")
          self.errors.add(:grade, I18n.translate("activerecord.errors.models.class_enrollment.grade_for_situation_registered")) unless self.grade.blank?
        when I18n.translate("activerecord.attributes.class_enrollment.situations.aproved")
	  self.errors.add(:grade, I18n.translate("activerecord.errors.models.class_enrollment.grade_for_situation_aproved", :minimum_grade_for_approval=>(CustomVariable.minimum_grade_for_approval.to_f/10.0).to_s.tr('.',','))) if (self.grade.blank? || self.grade < CustomVariable.minimum_grade_for_approval)
        when I18n.translate("activerecord.attributes.class_enrollment.situations.disapproved")
	  self.errors.add(:grade, I18n.translate("activerecord.errors.models.class_enrollment.grade_for_situation_disapproved", :minimum_grade_for_approval=>(CustomVariable.minimum_grade_for_approval.to_f/10.0).to_s.tr('.',','))) if (self.grade.blank? || self.grade >= CustomVariable.minimum_grade_for_approval)
      end
    else
      self.errors.add(:grade, I18n.translate("activerecord.errors.models.class_enrollment.grade_filled_for_course_without_score")) unless self.grade.blank?
    end
    self.errors.blank?
  end

  def disapproved_by_absence_for_situation
    case self.situation
      when I18n.translate("activerecord.attributes.class_enrollment.situations.registered")
        self.errors.add(:disapproved_by_absence, I18n.translate("activerecord.errors.models.class_enrollment.disapproved_by_absence_for_situation_registered")) if self.disapproved_by_absence
      when I18n.translate("activerecord.attributes.class_enrollment.situations.aproved")
        self.errors.add(:disapproved_by_absence, I18n.translate("activerecord.errors.models.class_enrollment.disapproved_by_absence_for_situation_aproved")) if self.disapproved_by_absence
      when I18n.translate("activerecord.attributes.class_enrollment.situations.disapproved")
	self.errors.add(:disapproved_by_absence, I18n.translate("activerecord.errors.models.class_enrollment.disapproved_by_absence_for_situation_disapproved", :grade_of_disapproval_for_absence=>(CustomVariable.grade_of_disapproval_for_absence.to_f/10.0).to_s.tr('.',','))) if self.disapproved_by_absence and course_has_grade and (not CustomVariable.grade_of_disapproval_for_absence.nil?) and ( (self.grade.blank?) or ( self.grade > CustomVariable.grade_of_disapproval_for_absence )  ) 
    end
    self.errors.blank?
  end

  def notify_student_and_advisor
    return if grade.nil? or !(saved_change_to_grade? or saved_change_to_situation? or saved_change_to_disapproved_by_absence?)
    info = {
        :name => enrollment.student.name,
        :course => course_class.label_with_course,
        :situation => situation,
        :grade => grade_to_view,
        :absence => ((attendance_to_label == "I") ? I18n.t('active_scaffold.true') : I18n.t('active_scaffold.false'))
    }
    message_to_student = {
        :to => enrollment.student.email,
        :subject => I18n.t('notifications.class_enrollment.email_to_student.subject', **info),
        :body => I18n.t('notifications.class_enrollment.email_to_student.body', **info)
    }
    emails = [message_to_student]
    enrollment.advisements.each do |advisement|
      professor_info = info.merge(:advisor_name => advisement.professor.name)
      emails << message_to_advisor = {
          :to => advisement.professor.email,
          :subject => I18n.t('notifications.class_enrollment.email_to_advisor.subject', professor_info),
          :body => I18n.t('notifications.class_enrollment.email_to_advisor.body', professor_info)
      }
    end
    Notifier.send_emails(notifications: emails)
  end

  def professor_changed_only_valid_fields
    campos_modificaveis = ['grade', 'situation', 'disapproved_by_absence', 'obs']
    campos_modificados  = self.changed

    campos_modificados.each do |campo_modificado|
      if !campos_modificaveis.include?(campo_modificado)
	errors.add(:class_enrollment, I18n.t("activerecord.errors.models.class_enrollment.changes_to_disallowed_fields"))
      end
    end
  end

  def set_request_status
    request = self.class_enrollment_request
    unless request.nil?
      request.class_enrollment = nil
      request.status = ClassEnrollmentRequest::VALID
      request.save
    end
  end

end
