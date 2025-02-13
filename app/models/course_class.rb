# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a Class instance of a Course taught by a Professor at a given semester
class CourseClass < ApplicationRecord
  has_paper_trail

  belongs_to :course, optional: false
  belongs_to :professor, optional: false

  has_many :class_enrollments, dependent: :destroy
  has_many :class_enrollment_requests, dependent: :destroy
  has_many :allocations, dependent: :destroy
  has_many :enrollments, through: :class_enrollments
  has_many :enrollment_requests, through: :class_enrollment_requests

  validates :course, presence: true
  validates :professor, presence: true
  validates :year, presence: true
  validates :semester,
    presence: true,
    inclusion: { in: YearSemester::SEMESTERS }
  validate :professor_changed_only_valid_fields,
    if: -> { can?(:post_grades, self) && cannot?(:update_all_fields, self) }


  attr_reader :changed_from_course_class
  before_save :set_changed_from_course_class

  def set_changed_from_course_class
    @changed_from_course_class = true
  end

  def to_label
    "#{name_with_class} - #{year}/#{semester}"
  end

  def semester_label
    "#{year}.#{semester}"
  end

  def label_for_email_subject
    "#{self.course.name} - #{year}/#{semester}"
  end

  def label_with_course
    name_l = self.name.blank? ? "" : " (#{self.name})"
    "#{self.course.name}#{name_l} - #{year}/#{semester}"
  end

  def class_enrollments_count
    self.class_enrollments.count
  end

  def name_with_class
    append_obs_schedule = ""
    if self.obs_schedule.present? && (self.obs_schedule.strip != "")
      append_obs_schedule = " - #{self.obs_schedule.strip}"
    end
    return "#{course.name}#{append_obs_schedule}" if
      name.blank? ||
      course.course_type.blank? ||
      !course.course_type.show_class_name
    "#{course.name} (#{name})#{append_obs_schedule}"
  end

  def name_with_class_formated_to_reports
    name_with_class.gsub("<", "&lt;")
  end

  private
    def professor_changed_only_valid_fields
      campos_modificaveis = []
      campos_modificados  = self.changed

      campos_modificados.each do |campo_modificado|
        if !campos_modificaveis.include?(campo_modificado)
          errors.add(:base, :changes_to_disallowed_fields)
        end
      end
    end

    delegate :can?, :cannot?, to: :ability

    def ability
      @ability ||= Ability.new(current_user)
    end
end
