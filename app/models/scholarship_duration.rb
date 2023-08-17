# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents the allocation of a Scholarship to an Enrollment
class ScholarshipDuration < ApplicationRecord
  include ::MonthYearConcern
  has_paper_trail

  belongs_to :scholarship, optional: false
  belongs_to :enrollment, optional: false
  has_many :scholarship_suspensions, dependent: :destroy


  validates :scholarship, presence: true
  validates :enrollment, presence: true
  validates :enrollment, uniqueness: {
    message: :enrollment_and_scholarship_uniqueness,
    if: :student_has_other_scholarship_duration
  }

  validate :if_scholarship_is_not_with_another_student
  validate :scholarship_level_equals_enrollment_level

  # validates if a scholarship duration start date isn't before it's end date
  validates_date :start_date,
    on_or_before: :end_date,
    on_or_before_message: :start_date_after_end_date
  validates :start_date, presence: true

  # validates if a cancel date of an scholarship duration is valid
  validates_date :cancel_date,
    on_or_after: :start_date,
    allow_nil: true,
    on_or_after_message: :cancel_date_before_start_date
  validates_date :cancel_date,
    on_or_before: :end_date, allow_nil: true,
    on_or_before_message: :cancel_date_after_end_date

  validate :check_date_boundaries_of_scholarship

  before_save :update_end_and_cancel_dates

  month_year_date :start_date
  month_year_date :end_date
  month_year_date :cancel_date

  def day_of(date)
    date.strftime("%Y%m%d").to_i
  end

  def check_date_boundaries_of_scholarship
    return if scholarship.blank?
    if start_date.present? && scholarship.start_date.present?
      if day_of(start_date) < day_of(scholarship.start_date)
        errors.add(:start_date, :start_date_before_scholarship_start_date)
      end
    end

    if scholarship.end_date.present?
      if cancel_date.present?
        if day_of(cancel_date) > day_of(scholarship.end_date)
          errors.add(:cancel_date, :cancel_date_after_scholarship_end_date)
        end
      elsif end_date.present? && day_of(end_date) > day_of(scholarship.end_date)
        errors.add(:end_date, :end_date_after_scholarship_end_date)
      end
    end
  end

  def init
    if self.start_date.nil?
      self.start_date = Date.today.beginning_of_month + 1.month
    end
    self.update_end_date
  end

  def update_end_date
    dates = []
    unless self.enrollment.nil? || self.enrollment.level.nil?
      default_duration = (self.enrollment.level.default_duration - 1).months
      dates << (self.enrollment.admission_date + default_duration).end_of_month
    end
    unless self.scholarship.nil?
      dates << self.scholarship.end_date unless self.scholarship.end_date.nil?
    end
    self.end_date = dates.min
  end

  def to_label
    label = ""

    if start_date
      label = I18n.localize(start_date, format: :monthyear)
    end
    if end_date
      label += " - #{I18n.localize(end_date, format: :monthyear)}"
    end
    label
  end

  # this validation is only called for checking uniqueness of scholarship durations
  # if start date of a new scholarship duration is earlier
  # than an existing scholarship duration then
  def student_has_other_scholarship_duration
    return false if enrollment.nil?
    return false if scholarship.nil?
    # Se a bolsa é mais antiga que a atual    scholarship.start_date < start_date
    # -> scholarship.cancel_date não é nulo -> scholarhsip.cancel < start_date
    # -> scholarship.cancel_date é nulo -> schoarslhip.end_date < start_date
    # Senão
    # -> cancel_date não é nulo -> schoarslhip.start_date > cancel_date
    # -> scholarship.cancel_date é nulo -> schoarslhip.start_date > end_date

    durations = ScholarshipDuration.where(enrollment_id: enrollment.id)
    durations = durations.where.not(id: self.id) if self.id.present?
    scholarships_with_student = durations.all

    scholarships_with_student.each do |scholarship|
      if scholarship.start_date <= start_date # se a bolsa é antiga
        if scholarship.cancel_date.nil?
          return true if scholarship.end_date >= start_date
        else
          return true if scholarship.cancel_date >= start_date
        end
      else # se a bolsa é futura
        if cancel_date.nil?
          return true if scholarship.start_date <= end_date
        else
          return true if scholarship.start_date <= cancel_date
        end
      end
    end

    false
  end

  def warning_message
    durations = ScholarshipDuration.where(scholarship_id: scholarship.id)
    durations = durations.where.not(id: self.id) if self.id.present?
    scholarships_with_student = durations.all

    message = nil
    scholarships_with_student.each do |scholarship|
      if scholarship.start_date <= start_date && scholarship.cancel_date.nil?
        message = I18n.t(
          "activerecord.errors.models.scholarship_duration.unfinished_scholarship"
        )
        break
      end
    end
    message
  end

  def if_scholarship_is_not_with_another_student
    return if scholarship.nil?
    durations = ScholarshipDuration.where(scholarship_id: scholarship.id)
    durations = durations.where.not(id: self.id) if self.id.present?
    scholarships_with_student = durations.all

    scholarships_with_student.each do |scholarship|
      if scholarship.start_date <= start_date # se a bolsa é antiga
        if scholarship.cancel_date.nil?
          if scholarship.end_date >= start_date
            errors.add(:start_date, :start_date_before_scholarship_end_date)
            break
          end
        else
          if scholarship.cancel_date >= start_date
            errors.add(:start_date, :start_date_before_scholarship_cancel_date)
            break
          end
        end
      else # se a bolsa é futura
        if cancel_date.nil?
          if scholarship.start_date <= end_date
            errors.add(
              :end_date, :scholarship_start_date_after_end_or_cancel_date
            )
            break
          end
        else
          if scholarship.start_date <= cancel_date
            errors.add(
              :cancel_date, :scholarship_start_date_after_end_or_cancel_date
            )
            break
          end
        end
      end
    end
  end

  def last_date
    return self.cancel_date.end_of_month unless self.cancel_date.nil?
    self.end_date.end_of_month
  end

  def was_cancelled?
    return false if self.cancel_date.nil?
    self.end_date != self.cancel_date
  end

  def active?(options = {})
    date = options[:date].nil? ? Date.today : options[:date].to_date
    return false if date < self.start_date
    return self.end_date.end_of_month >= date if self.cancel_date.nil?
    (self.cancel_date - 1.month).end_of_month >= date
  end

  def update_end_and_cancel_dates
    self.end_date = self.end_date.end_of_month unless self.end_date.nil?
    self.cancel_date = self.cancel_date.end_of_month unless self.cancel_date.nil?
  end

  def scholarship_level_equals_enrollment_level
    return unless defined?(scholarship.level_id)
    return unless defined?(enrollment.level_id)
    return if scholarship.level_id == enrollment.level_id
    errors.add(
      :scholarship, :the_levels_of_scholarship_and_enrollment_are_different
    )
  end
end
