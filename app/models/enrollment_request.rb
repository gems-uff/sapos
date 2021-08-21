# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class EnrollmentRequest < ApplicationRecord
  belongs_to :enrollment
  has_many :class_enrollment_requests, :dependent => :destroy
  has_many :course_classes, through: :class_enrollment_requests

  has_paper_trail

  IMPOSSIBLE = ["id = -1"]

  validates :year, :presence => true
  validates :semester, :presence => true
  validates :enrollment, :presence => true
  validates :status, :presence => true, :inclusion => {:in => ClassEnrollmentRequest::STATUSES}
  validates_uniqueness_of :enrollment, :scope => [:year, :semester]
  validates :class_enrollment_requests, :length => { minimum: 1, message: :at_least_one_class}
  validate :validate_effected_status

  accepts_nested_attributes_for :class_enrollment_requests, :course_classes

  def self.pendency_condition
    return IMPOSSIBLE if current_user.nil?
    er = EnrollmentRequest.arel_table.dup
    cer = ClassEnrollmentRequest.arel_table
    er.table_alias = 'er'
    check_status = er
      .join(cer)
      .on(cer[:enrollment_request_id].eq(er[:id]))
      .where(cer[:status].eq(ClassEnrollmentRequest::REQUESTED))
    if current_user.role_id == Role::ROLE_COORDENACAO || current_user.role_id == Role::ROLE_COORDENACAO
      return [
        "id IN (#{check_status.project(er[:id]).to_sql})",
      ]
    end
    if current_user.role_id == Role::ROLE_PROFESSOR && ! current_user.professor.nil?
      check_status = check_status.where(er[:enrollment_id].in(current_user.professor.enrollments.map(&:id)))
      return [
        "id IN (#{check_status.project(er[:id]).to_sql})",
      ]
    end
    IMPOSSIBLE
  end

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

  def refresh_status!
    if self.status == ClassEnrollmentRequest::EFFECTED
      nstatus = self.class_enrollment_requests.collect(&:status).max_by {|stat| ClassEnrollmentRequest::STATUSES_PRIORITY.index stat}
      self.status = nstatus
      self.save 
    elsif self.class_enrollment_requests.collect(&:status).all? { |stat| stat == ClassEnrollmentRequest::EFFECTED }
      self.status = ClassEnrollmentRequest::EFFECTED
      self.save
    end
  end

  protected

  def validate_effected_status
    if self.status == ClassEnrollmentRequest::EFFECTED
      if self.class_enrollment_requests.any? { |cer| cer.status != ClassEnrollmentRequest::EFFECTED }
        errors.add(:status, :class_enrollment_request_is_not_effected)
      end
    end
  end

 

end
