class ClassEnrollment < ActiveRecord::Base
  belongs_to :course_class
  belongs_to :enrollment

  SITUATIONS = [I18n.translate("activerecord.attributes.class_enrollment.situations.registered"), I18n.translate("activerecord.attributes.class_enrollment.situations.aproved"), I18n.translate("activerecord.attributes.class_enrollment.situations.disapproved")]

  validates :enrollment, :presence => true
  validates :course_class, :presence => true
  validates :situation, :presence => true, :inclusion => { :in => SITUATIONS }
  validates :grade, :numericality => {:greater_than_or_equal_to => 0, :less_than_or_equal_to => 100}, :if => :grade_filled?

  def grade_filled?
    !grade.nil?
  end

end
