# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a CustomVariable configuration
class CustomVariable < ApplicationRecord
  has_paper_trail

  SAPOS_MAIL = "sapos@sapos.ic.uff.br"

  VARIABLES = {
    "single_advisor_points" => :text,
    "multiple_advisor_points" => :text,
    "identity_issuing_country" => :text,
    "class_schedule_text" => :text,
    "redirect_email" => :text,
    "reply_to" => :text,
    "notification_footer" => :text,
    "minimum_grade_for_approval" => :text,
    "grade_of_disapproval_for_absence" => :text,
    "professor_login_can_post_grades" => :text,
    "month_year_range" => :text,
    "year_semester_range" => :text,
    "past_calendar_range" => :text,
    "academic_calendar_range" => :text,
    "quadrennial_period" => :text,
  }

  validates :variable, presence: true
  validate :check_constraints_between_variables
  before_destroy :validate_destroy
  before_validation :validate_create, on: :create

  def self.single_advisor_points
    config = CustomVariable.find_by_variable(:single_advisor_points)
    config.blank? ? 1.0 : config.value.to_f
  end

  def self.multiple_advisor_points
    config = CustomVariable.find_by_variable(:multiple_advisor_points)
    config.blank? ? 0.5 : config.value.to_f
  end

  def self.identity_issuing_country
    config = CustomVariable.find_by_variable(:identity_issuing_country)
    config.blank? ? "" : config.value
  end

  def self.class_schedule_text
    config = CustomVariable.find_by_variable(:class_schedule_text)
    config.blank? ? "" : config.value
  end

  def self.redirect_email
    config = CustomVariable.find_by_variable(:redirect_email)
    config.blank? ? nil : (config.value || "")
  end

  def self.reply_to
    default = ActionMailer::Base.default[:from]
    config = CustomVariable.find_by_variable(:reply_to)
    config.blank? ? default : (config.value || default)
  end

  def self.notification_footer
    config = CustomVariable.find_by_variable(:notification_footer)
    config.blank? ? "" : config.value
  end

  def self.minimum_grade_for_approval
    config = CustomVariable.find_by_variable(:minimum_grade_for_approval)
    return 60 if config.blank? || config.value.blank?
    ((config.value.tr(",", ".").to_f) * 10.0).to_i
  end

  def self.grade_of_disapproval_for_absence
    config = CustomVariable.find_by_variable(:grade_of_disapproval_for_absence)
    return nil if config.blank? || config.value.blank?
    ((config.value.tr(",", ".").to_f) * 10.0).to_i
  end

  def self.professor_login_can_post_grades
    config = CustomVariable.find_by_variable(:professor_login_can_post_grades)
    if (!config.blank?) && (!config.value.nil?)
      formatted_value = config.value.strip.downcase
      return formatted_value if
        (formatted_value == "yes") || (formatted_value == "yes_all_semesters")
    end
    "no"
  end

  def self.month_year_range
    config = CustomVariable.find_by_variable(:month_year_range)
    self.parse_range(config, [20, 10, false])
  end

  def self.year_semester_range
    config = CustomVariable.find_by_variable(:year_semester_range)
    self.parse_range(config, [20, 1, true])
  end

  def self.past_calendar_range
    config = CustomVariable.find_by_variable(:past_calendar_range)
    self.parse_calendar_range(config, [100, 0, false])
  end

  def self.academic_calendar_range
    config = CustomVariable.find_by_variable(:academic_calendar_range)
    self.parse_calendar_range(config, [20, 10, false])
  end

  def self.quadrennial_period
    config = CustomVariable.find_by_variable(:quadrennial_period)
    config.blank? ? "Not defined" : config.value
  end


  def to_label
    self.variable.to_s
  end

  private
    def self.parse_range(config, default)
      return default if config.blank? || config.value.blank?
      swap = false
      value = config.value
      if value.starts_with?("~")
        swap = true
        value = value[1..]
      end
      return value.split(":").map(&:to_i) + [swap] if value.include? ":"
      [value.to_i, value.to_i, swap]
    end

    def self.parse_calendar_range(config, default)
      start_year, end_year, _ = self.parse_range(config, default)
      start_year = -start_year
      start_year_t = start_year <= 0 ? "-#{-start_year}" : "+#{start_year}"
      end_year_t = end_year <= 0 ? "-#{-end_year}" : "+#{end_year}"
      {
        "minDate" => "#{start_year_t}Y",
        "maxDate" => "#{end_year_t}Y",
        "yearRange": "#{start_year_t}:#{end_year_t}"
      }
    end

    def check_constraints_between_variables
      case self.variable
      when "minimum_grade_for_approval"
        grade = CustomVariable.grade_of_disapproval_for_absence
        minimum = self.value.blank? ? 6.0 : self.value.tr(",", ".").to_f
        self.errors.add(
          :value,
          :minimum_grade_for_approval_not_gt_grade_of_disapproval_for_absence, {
            minimum_grade_for_approval: minimum.to_s,
            grade_of_disapproval_for_absence: (grade.to_f / 10.0).to_s
          }
        ) if !grade.nil? && (grade >= (minimum * 10.0).to_i)
      when "grade_of_disapproval_for_absence"
        minimum = CustomVariable.minimum_grade_for_approval
        grade = self.value.tr(",", ".").to_f
        self.errors.add(
          :value,
          :grade_of_disapproval_for_absence_not_lt_minimum_grade_for_approval, {
            grade_of_disapproval_for_absence: grade.to_s,
            minimum_grade_for_approval: (minimum.to_f / 10.0).to_s
          }
        ) if (!self.value.blank?) && ((grade * 10.0).to_i >= minimum)
      end
    end

    def validate_destroy
      case self.variable
      when "minimum_grade_for_approval"
        grade = CustomVariable.grade_of_disapproval_for_absence
        self.errors.add(
          :base, :validate_destroy_of_minimum_grade_for_approval
        ) if (!grade.blank?) && (grade >= 60)
      end
      self.errors.blank?
    end

    def validate_create
      case self.variable
      when "minimum_grade_for_approval", "grade_of_disapproval_for_absence"
        if CustomVariable.find_by_variable(self.variable).present?
          self.errors.add(:base, :check_duplicate, variable: self.variable)
        end
      end
    end
end
