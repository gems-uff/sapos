# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CourseClass < ActiveRecord::Base
  
  attr_accessible :year, :semester, :professor, :course

  belongs_to :course
  belongs_to :professor

  has_paper_trail

  has_many :class_enrollments, :dependent => :destroy
  has_many :allocations, :dependent => :destroy

  has_many :enrollments, :through => :class_enrollments

  SEMESTERS = [1,2]

  validates :course, :presence => true
  validates :professor, :presence => true
  validates :year, :presence => true
  validates :semester, :presence => true, :inclusion => {:in => SEMESTERS}

  def to_label
    "#{name || course.name} - #{year}/#{semester}"
  end

  def label_with_course
    "#{self.course.name + (self.name.blank? ? '' : " (#{self.name})")} - #{year}/#{semester}"
  end

  def class_enrollments_count
    self.class_enrollments.count
  end
end
