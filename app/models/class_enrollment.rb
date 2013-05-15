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
    if new_grade.is_a?(String)
      split = new_grade.split('.')
      #if the string represents a float, convert the float to integer
      #ex: if new_grade is 9.0, it will be converted to 90
      new_grade = split[0].to_i*10 + split[1].to_i if split.size > 1
    end
    super(new_grade)
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

end
