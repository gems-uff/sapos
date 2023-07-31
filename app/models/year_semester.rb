# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Provides functions to calculate the dates based on Year and Semester
class YearSemester
  attr_accessor :year, :semester

  SEMESTERS = [1, 2]

  FIRST_SEMESTER = 1
  SECOND_SEMESTER = 2

  FIRST_SEMESTER_BEGIN_MONTH = 3
  FIRST_SEMESTER_BEGIN_DAY = 1
  SECOND_SEMESTER_BEGIN_MONTH = 8
  SECOND_SEMESTER_BEGIN_DAY = 1

  def self.selectable_years
    ((Date.today.year - 5)..Date.today.year + 1).map { |y| y }.reverse
  end

  def self.current
    today = Date.today
    self.on_date(today)
  end

  def self.on_date(date)
    first_semester = Date.parse("#{date.year}/#{FIRST_SEMESTER_BEGIN_MONTH}/#{FIRST_SEMESTER_BEGIN_DAY}")
    second_semester = Date.parse("#{date.year}/#{SECOND_SEMESTER_BEGIN_MONTH}/#{SECOND_SEMESTER_BEGIN_DAY}")

    if date.between?(first_semester, second_semester - 1.day)
      current_semester = FIRST_SEMESTER
      current_year = date.year
    else
      current_semester = SECOND_SEMESTER
      if date < first_semester
        current_year = date.year - 1
      else
        current_year = date.year
      end
    end
    year_semester = YearSemester.new
    year_semester.year = current_year
    year_semester.semester = current_semester
    year_semester
  end

  def initialize(options = {})
    self.year ||= options[:year]
    self.semester ||= options[:semester]
  end

  def semester_end
    self.next_semester_start - 1.day
  end

  def semester_begin
    if self.first_semester?
      semester_begin_month = FIRST_SEMESTER_BEGIN_MONTH
      semester_begin_day = FIRST_SEMESTER_BEGIN_DAY
    else
      semester_begin_month = SECOND_SEMESTER_BEGIN_MONTH
      semester_begin_day = SECOND_SEMESTER_BEGIN_DAY
    end
    Date.parse("#{self.year}/#{semester_begin_month}/#{semester_begin_day}")
  end

  def next_semester_start
    next_semester = first_semester? ? SECOND_SEMESTER : FIRST_SEMESTER
    if next_semester == FIRST_SEMESTER
      next_semester_begin_year = self.year + 1
      next_semester_begin_month = FIRST_SEMESTER_BEGIN_MONTH
      next_semester_begin_day = FIRST_SEMESTER_BEGIN_DAY
    else
      next_semester_begin_year = self.year
      next_semester_begin_month = SECOND_SEMESTER_BEGIN_MONTH
      next_semester_begin_day = SECOND_SEMESTER_BEGIN_DAY
    end
    Date.parse("#{next_semester_begin_year}/#{next_semester_begin_month}/#{next_semester_begin_day}")
  end

  def first_semester?
    self.semester == FIRST_SEMESTER
  end

  def second_semester?
    self.semester == SECOND_SEMESTER
  end

  def opposite_semester
    if first_semester?
      SECOND_SEMESTER
    else
      FIRST_SEMESTER
    end
  end

  def toggle_semester
    self.semester = self.opposite_semester
  end

  def -(number_of_semesters)
    if number_of_semesters < 0
      self.+(number_of_semesters * -1)
    else
      result_year = self.year
      result_semester = self.semester
      if number_of_semesters % 2 == 1
        result_year -= 1 if self.first_semester?
        result_semester = self.opposite_semester
      end
      result_year -= (number_of_semesters / 2)
      year_semester = YearSemester.new
      year_semester.semester = result_semester
      year_semester.year = result_year
      year_semester
    end
  end

  def +(number_of_semesters)
    if number_of_semesters < 0
      self.-(number_of_semesters * -1)
    else
      result_year = self.year
      result_semester = self.semester
      if number_of_semesters % 2 == 1
        result_year += 1 if self.second_semester?
        result_semester = self.opposite_semester
      end
      result_year += (number_of_semesters / 2)
      year_semester = YearSemester.new
      year_semester.semester = result_semester
      year_semester.year = result_year
      year_semester
    end
  end

  def increase_semesters(number_of_semesters)
    result = self.+ number_of_semesters
    self.year = result.year
    self.semester = result.semester
    self
  end

  def decrease_semesters(number_of_semesters)
    result = self.- number_of_semesters
    self.year = result.year
    self.semester = result.semester
    self
  end
end
