# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a Class instance of a Course taught by a Professor at a given semester
class CourseClass < ApplicationRecord
  include GradePostingGuardConcern

  has_paper_trail

  belongs_to :course, optional: false
  belongs_to :professor, optional: false

  has_many :class_enrollments, dependent: :destroy,
    before_remove: :note_removed_class_enrollment
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
  validate :professor_changed_only_valid_fields, if: :restricted_to_grade_fields?


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

  def start_date
    ys = YearSemester.new(year: year, semester: semester)
    ys.semester_begin
  end

  def end_date
    ys = YearSemester.new(year: year, semester: semester)
    ys.semester_end
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

  def self.pendency_condition(user = nil)
    user ||= current_user
    return ["0 = -1"] if user.blank?
    return ["0 = -1"] if user.cannot?(:read_pendencies, CourseClass)

    semester = ClassSchedule.find_by(year: YearSemester.current.year, semester: YearSemester.current.semester)

    if semester && semester.show_period_end?
      course_type_arel = CourseType.arel_table.dup
      course_arel = Course.arel_table.dup
      course_class_arel = CourseClass.arel_table.dup
      class_enrollment_arel = ClassEnrollment.arel_table.dup

      query = course_type_arel
      .join(course_arel)
      .on(course_type_arel[:id].eq(course_arel[:course_type_id]))
      .join(course_class_arel)
      .on(course_arel[:id].eq(course_class_arel[:course_id]))
      .join(class_enrollment_arel)
      .on(course_class_arel[:id].eq(class_enrollment_arel[:course_class_id]))
      .where(class_enrollment_arel[:situation].eq(ClassEnrollment::REGISTERED)
      .and(course_class_arel[:year].eq(YearSemester.current.year))
      .and(course_class_arel[:semester].eq(YearSemester.current.semester))
      .and(course_type_arel[:schedulable].eq(true)))

      if user.professor.present?
        query = query.where(course_class_arel[:professor_id].eq(user.professor.id))
      end

      return [course_class_arel[:id].in(query.project(course_class_arel[:id])).to_sql]
    end
    ["0 = -1"]
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
      # O subformulario grava a associacao inteira: a inscricao que nao vem no
      # envio sai da turma e, com dependent: :destroy, e apagada na hora. Quem
      # so lanca nota nao apaga inscricao; o erro aqui desfaz a transacao do
      # envio, e a inscricao volta.
      if @removed_class_enrollments.present?
        errors.add(:base, :changes_to_disallowed_fields)
      end
    end

    def note_removed_class_enrollment(class_enrollment)
      (@removed_class_enrollments ||= []) << class_enrollment
    end

    delegate :can?, :cannot?, to: :ability

    def ability
      @ability ||= Ability.new(current_user)
    end
end
