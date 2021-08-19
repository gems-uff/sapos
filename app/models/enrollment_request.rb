# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class EnrollmentRequest < ApplicationRecord
  belongs_to :enrollment
  has_many :class_enrollment_requests, :dependent => :destroy
  has_many :course_classes, through: :class_enrollment_requests

  has_paper_trail

  validates :year, :presence => true
  validates :semester, :presence => true
  validates :enrollment, :presence => true
  validates_uniqueness_of :enrollment, :scope => [:year, :semester]
  validates :class_enrollment_requests, :length => { minimum: 1, message: :at_least_one_class}

  accepts_nested_attributes_for :class_enrollment_requests, :course_classes

  def to_label
    "[#{self.year}.#{self.semester}] #{self.enrollment.to_label}"
  end

  def course_class_ids
    self.class_enrollment_requests.collect { |cer| cer.course_class_id }
  end

  def assign_course_class_ids(course_classes)
    # course classes is a list of strings representing course_class ids
    to_remove = self.class_enrollment_requests.filter {|cer| ! course_classes.include? cer.course_class_id.to_s }
    course_classes.each do |course_class_id|
      next if course_class_id.empty?
      if self.class_enrollment_requests.find_by(course_class_id: course_class_id).nil?
        self.class_enrollment_requests.build(course_class_id: course_class_id)
      end
    end
    to_remove.each(&:mark_for_destruction)
  end
end
