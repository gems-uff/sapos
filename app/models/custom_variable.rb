# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a CustomVariable configuration
class CustomVariable < ApplicationRecord
  has_paper_trail

  VARIABLES = {
    "single_advisor_points" => :text,
    "multiple_advisor_points" => :text,
    "program_level" => :text,
    "identity_issuing_country" => :text,
    "class_schedule_text" => :text,
    "redirect_email" => :text,
    "notification_footer" => :text,
    "minimum_grade_for_approval" => :text,
    "grade_of_disapproval_for_absence" => :text,
    "professor_login_can_post_grades" => :text,
    "month_year_range" => :text,
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

  def self.program_level
    config = CustomVariable.find_by_variable(:program_level)
    config.blank? ? nil : config.value.to_i
  end

  def self.identity_issuing_country
    config = CustomVariable.find_by_variable(:identity_issuing_country)
    Country.find_by_name(config.blank? ? "Brasil" : config.value)
  end

  def self.class_schedule_text
    config = CustomVariable.find_by_variable(:class_schedule_text)
    config.blank? ? "" : config.value
  end

  def self.redirect_email
    config = CustomVariable.find_by_variable(:redirect_email)
    config.blank? ? nil : (config.value || "")
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
    else
      "no"
    end
  end

  def self.month_year_range
    config = CustomVariable.find_by_variable(:month_year_range)
    return [20, 10, false] if config.blank? || config.value.blank?
    swap = false
    value = config.value
    if value.starts_with?("-")
      swap = true
      value = value[1..]
    end
    return value.split(":").map(&:to_i) + [swap] if value.include? ":"
    [value.to_i, value.to_i, swap]
  end

  def to_label
    self.variable.to_s
  end

  private
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
          self.errors.add(:base, :check_duplicate, { variable: self.variable })
        end
      end
    end
end
