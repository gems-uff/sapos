# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CourseClass < ApplicationRecord
  
  belongs_to :course
  belongs_to :professor

  has_paper_trail

  has_many :class_enrollments, :dependent => :destroy
  has_many :class_enrollment_requests, :dependent => :destroy
  has_many :allocations, :dependent => :destroy

  has_many :enrollments, :through => :class_enrollments
  has_many :enrollment_requests, :through => :class_enrollments


  validates :course, :presence => true
  validates :professor, :presence => true
  validates :year, :presence => true
  validates :semester, :presence => true, :inclusion => {:in => YearSemester::SEMESTERS}
  validate :professor_changed_only_valid_fields, if: -> {current_user && (current_user.role_id == Role::ROLE_PROFESSOR)}

  attr_reader :changed_from_course_class
  before_save :set_changed_from_course_class

  def set_changed_from_course_class
    @changed_from_course_class = true	  
  end

  def to_label
    "#{name_with_class} - #{year}/#{semester}"
  end

  def label_with_course
    "#{self.course.name + (self.name.blank? ? '' : " (#{self.name})")} - #{year}/#{semester}"
  end

  def class_enrollments_count
    self.class_enrollments.count
  end

  def name_with_class
    return course.name if name.nil? or name.empty? or course.course_type.nil? or not course.course_type.show_class_name
    "#{course.name} (#{name})"
  end

  private

  def professor_changed_only_valid_fields
    campos_modificaveis = []
    campos_modificados  = self.changed

    campos_modificados.each do |campo_modificado|
      if !campos_modificaveis.include?(campo_modificado)
        errors.add(:course_class, I18n.t("activerecord.errors.models.course_class.changes_to_disallowed_fields"))
      end
    end
  end

end
