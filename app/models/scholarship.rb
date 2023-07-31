# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a Scholarship of a given Level and ScholarshipType from a Sponsor
class Scholarship < ApplicationRecord
  include ::MonthYearConcern
  has_paper_trail

  belongs_to :level, optional: false
  belongs_to :sponsor, optional: false
  belongs_to :scholarship_type, optional: true
  belongs_to :professor, optional: true

  has_many :scholarship_durations, dependent: :destroy
  has_many :enrollments, through: :scholarship_durations

  validates :scholarship_number, presence: true, uniqueness: true
  validates :start_date, presence: true
  validates_date :end_date, on_or_after: :start_date, allow_nil: true

  before_save :update_end_date

  month_year_date :start_date
  month_year_date :end_date

  def to_label
    "#{scholarship_number}"
  end

  def last_date
    return (Date.today + 100.years).end_of_month if self.end_date.nil?
    self.end_date.end_of_month
  end

  def update_end_date
    self.end_date = self.end_date.end_of_month unless self.end_date.nil?
  end
end
