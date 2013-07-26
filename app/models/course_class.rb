# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CourseClass < ActiveRecord::Base
  belongs_to :course
  belongs_to :professor

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

  def class_enrollments_count
    self.class_enrollments.count
  end
end
