# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a Dismissal for a Enrollment
class Dismissal < ApplicationRecord
  include ::MonthYearConcern

  has_paper_trail

  belongs_to :dismissal_reason, optional: false
  belongs_to :enrollment, optional: false

  validates :dismissal_reason, presence: true
  validates :enrollment, presence: true
  validates :date, presence: true
  validates_date :date,
    on_or_after: :enrollment_admission_date,
    on_or_after_message: :date_before_enrollment_admission_date

  validate :if_enrollment_has_not_scholarship

  month_year_date :date

  def to_label
    date.to_fs
  end

  def enrollment_admission_date
    enrollment.admission_date unless enrollment.blank?
  end

  def if_enrollment_has_not_scholarship
    return if enrollment.blank?
    return if date.blank?
    any_active_scholarship = enrollment.scholarship_durations.any? do |sd|
      sd.active?(date: date)
    end
    if any_active_scholarship
      errors.add(:enrollment, :enrollment_has_scholarship)
    end
  end
end
