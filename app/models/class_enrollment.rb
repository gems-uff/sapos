# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ClassEnrollment < ActiveRecord::Base
  belongs_to :course_class
  belongs_to :enrollment

  has_paper_trail

  REGISTERED = I18n.translate("activerecord.attributes.class_enrollment.situations.registered")
  APPROVED = I18n.translate("activerecord.attributes.class_enrollment.situations.aproved")
  DISAPPROVED = I18n.translate("activerecord.attributes.class_enrollment.situations.disapproved")
  SITUATIONS = [REGISTERED, APPROVED, DISAPPROVED]

  validates :enrollment, :presence => true
  validates :course_class, :presence => true
  validates :course_class_id, :uniqueness => {:scope => :enrollment_id}
  validates :situation, :presence => true, :inclusion => {:in => SITUATIONS}
  validates :grade, :numericality => {:greater_than_or_equal_to => 0, :less_than_or_equal_to => 100}, :if => :grade_filled?
  validate :grade_for_situation
  validate :disapproved_by_absence_for_situation
  validate :check_multiple_class_enrollment_allowed

  after_save :notify_student_and_advisor

  def check_multiple_class_enrollment_allowed
    return if not self.course_class
      other_enrollments = ClassEnrollment.
          joins(:course_class => {:course => :course_type}).
          includes(:course_class => {:course => :course_type}).
          where(CourseType.arel_table[:allow_multiple_classes].eq(false)).
          where(:enrollment_id => self.enrollment_id).
          where(ClassEnrollment.arel_table[:situation].not_eq(DISAPPROVED)).
          where(Course.arel_table[:id].eq( self.course_class.course_id)).
          group(:enrollment_id).
          having("count(course_id) > 1")


      unless other_enrollments.empty?
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

  def should_send_email_to_professor?
    (!self.id.nil?) and 
    (
      self.grade_changed? or 
      self.situation_changed? or 
      self.disapproved_by_absence_changed?
    )
  end

  private
  def grade_for_situation
    if course_has_grade
      case self.situation
        when I18n.translate("activerecord.attributes.class_enrollment.situations.registered")
          self.errors.add(:grade, I18n.translate("activerecord.errors.models.class_enrollment.grade_for_situation_registered")) unless self.grade.blank?
        when I18n.translate("activerecord.attributes.class_enrollment.situations.aproved")
          self.errors.add(:grade, I18n.translate("activerecord.errors.models.class_enrollment.grade_for_situation_aproved")) if (self.grade.blank? || self.grade < 60)
        when I18n.translate("activerecord.attributes.class_enrollment.situations.disapproved")
          self.errors.add(:grade, I18n.translate("activerecord.errors.models.class_enrollment.grade_for_situation_disapproved")) if (self.grade.blank? || self.grade >= 60)
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
    end
    self.errors.blank?
  end

  def notify_student_and_advisor
    return if grade.nil? or !(grade_changed? or situation_changed? or disapproved_by_absence_changed?)
    info = {
        :name => enrollment.student.name,
        :course => course_class.label_with_course,
        :situation => situation,
        :grade => grade_to_view,
        :absence => ((attendance_to_label == "I") ? I18n.t('active_scaffold.true') : I18n.t('active_scaffold.false'))
    }
    message_to_student = {
        :to => enrollment.student.email,
        :subject => I18n.t('notifications.class_enrollment.email_to_student.subject', info),
        :body => I18n.t('notifications.class_enrollment.email_to_student.body', info)
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


end
