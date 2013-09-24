# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ClassEnrollment < ActiveRecord::Base
  belongs_to :course_class
  belongs_to :enrollment

  SITUATIONS = [I18n.translate("activerecord.attributes.class_enrollment.situations.registered"), I18n.translate("activerecord.attributes.class_enrollment.situations.aproved"), I18n.translate("activerecord.attributes.class_enrollment.situations.disapproved")]

  validates :enrollment, :presence => true
  validates :course_class, :presence => true
  validates :course_class_id, :uniqueness => {:scope => :enrollment_id}
  validates :situation, :presence => true, :inclusion => {:in => SITUATIONS}
  validates :grade, :numericality => {:greater_than_or_equal_to => 0, :less_than_or_equal_to => 100}, :if => :grade_filled?
  validate :grade_for_situation
  validate :disapproved_by_absence_for_situation

  def to_label
    "#{self.enrollment.student.name} - #{self.course_class.name || self.course_class.course.name}"
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

end
