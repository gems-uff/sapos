# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents the ClassSchedule of a semester
class ClassSchedule < ApplicationRecord
  has_paper_trail

  validates :year, presence: true
  validates :semester,
    presence: true,
    inclusion: { in: YearSemester::SEMESTERS },
    uniqueness: { scope: [:year] }
  validates :enrollment_start, presence: true
  validates :enrollment_end, presence: true
  validates :period_start, presence: true
  validates :enrollment_insert, presence: true
  validates :enrollment_remove, presence: true
  validates :period_end, presence: true
  validates :grades_deadline, presence: true

  def to_label
    "#{year}.#{semester}"
  end

  def show_period_end?(now = nil)
    now ||= Time.now
    self.period_end && self.period_end - 7.days <= now
  end

  def grades_deadline_to_view
    "#{ "%.2i" % (self.grades_deadline.day)}/#{ "%.2i" % (self.grades_deadline.month)}"
  end

  def main_enroll_open?(now = nil)
    now ||= Time.now
    self.enrollment_start <= now && now <= self.enrollment_end
  end

  def adjust_enroll_insert_open?(now = nil)
    now ||= Time.now
    self.period_start <= now && now <= self.enrollment_insert
  end

  def adjust_enroll_remove_open?(now = nil)
    now ||= Time.now
    self.period_start <= now && now <= self.enrollment_remove
  end

  def enroll_open?(now = nil)
    now ||= Time.now
    return true if main_enroll_open?(now)
    return true if adjust_enroll_insert_open?(now)
    return true if adjust_enroll_remove_open?(now)
    false
  end

  def open_for_removing_class_enrollments?(now = nil)
    now ||= Time.now
    main_enroll_open?(now) || adjust_enroll_remove_open?(now)
  end

  def open_for_inserting_class_enrollments?(now = nil)
    now ||= Time.now
    main_enroll_open?(now) || adjust_enroll_insert_open?(now)
  end

  def self.arel_main_enroll_open?(now = nil)
    now ||= Time.now
    ClassSchedule.arel_table[:enrollment_start].lteq(now)
    .and(ClassSchedule.arel_table[:enrollment_end].gteq(now))
  end

  def self.arel_adjust_enroll_insert_open?(now = nil)
    now ||= Time.now
    ClassSchedule.arel_table[:period_start].lteq(now)
    .and(ClassSchedule.arel_table[:enrollment_insert].gteq(now))
  end

  def self.arel_adjust_enroll_remove_open?(now = nil)
    now ||= Time.now
    ClassSchedule.arel_table[:period_start].lteq(now)
    .and(ClassSchedule.arel_table[:enrollment_remove].gteq(now))
  end

  def self.arel_enroll_open?
    ClassSchedule.arel_main_enroll_open?
    .or(ClassSchedule.arel_adjust_enroll_insert_open?)
    .or(ClassSchedule.arel_adjust_enroll_remove_open?)
  end
end
