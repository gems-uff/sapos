# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a hold on a ScholarshipDuration
class ScholarshipSuspension < ApplicationRecord
  include ::MonthYearConcern
  has_paper_trail

  ACTIVE = I18n.t(
    "activerecord.attributes.scholarship_suspension.active_options.active"
  )
  INACTIVE = I18n.t(
    "activerecord.attributes.scholarship_suspension.active_options.inactive"
  )

  belongs_to :scholarship_duration, optional: false

  validates :scholarship_duration, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  validates_date :start_date,
    on_or_before: :end_date,
    on_or_before_message: :suspension_start_date_after_end_date
  validates_date :start_date,
    on_or_after: :scholarship_duration_start_date,
    on_or_after_message: :suspension_start_date_before_scholarship_start_date
  validates_date :start_date,
    on_or_before: :scholarship_duration_end_date,
    on_or_before_message: :suspension_start_date_after_scholarship_end_date

  validates_date :end_date,
    on_or_before: :scholarship_duration_end_date,
    on_or_before_message: :suspension_end_date_after_scholarship_end_date

  validate :if_there_is_no_other_active_suspension

  month_year_date :start_date
  month_year_date :end_date

  before_save :update_end_date

  def if_there_is_no_other_active_suspension
    return if scholarship_duration.nil? || start_date.nil? || end_date.nil?
    return unless active

    ss = ScholarshipSuspension.arel_table
    suspensions = ScholarshipSuspension.where(
      scholarship_duration_id: scholarship_duration.id,
      active: true
    ).where(
      ss[:id].not_eq(id).and(
        ss[:start_date].gteq(start_date)
        .and(ss[:start_date].lteq(end_date))
        .or(
          ss[:start_date].lteq(start_date)
          .and(ss[:end_date].gteq(start_date))
        )
      )
    )
    unless suspensions.empty?
      errors.add(:base, :active_suspension)
    end
  end

  def to_label
    label = I18n.localize(start_date, format: :monthyear)
    label += " - #{I18n.localize(end_date, format: :monthyear)}: "
    label += active_label
    label
  end

  def active_label
    active ? ACTIVE : INACTIVE
  end

  def scholarship_duration_start_date
    return nil if scholarship_duration.nil?
    scholarship_duration.start_date
  end

  def scholarship_duration_end_date
    return nil if scholarship_duration.nil?
    scholarship_duration.end_date
  end

  def update_end_date
    self.end_date = self.end_date.end_of_month unless self.end_date.nil?
  end
end
