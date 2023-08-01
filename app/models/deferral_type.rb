# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a DeferralType for a Phase
class DeferralType < ApplicationRecord
  has_paper_trail

  belongs_to :phase, optional: false
  has_many :deferrals, dependent: :restrict_with_exception


  validates :phase, presence: true
  validates :name, presence: true

  validate :that_duration_is_not_blank

  def that_duration_is_not_blank
    return unless [0, nil].include?(self.duration_semesters)
    return unless [0, nil].include?(self.duration_months)
    return unless [0, nil].include?(self.duration_days)
    errors.add(:duration, :blank_duration)
  end

  def to_label
    "#{self.name}"
  end

  def duration
    { semesters: self.duration_semesters, months: self.duration_months, days: self.duration_days }
  end

  def self.find_all_for_enrollment(enrollment)
    if enrollment.blank?
      ["deferral_types.id IN (
        SELECT deferral_types.id
        FROM deferral_types
        INNER JOIN phases ON deferral_types.phase_id = phases.id
        WHERE (phases.active = 1)
      )"]
    else
      ["deferral_types.id IN (
        SELECT deferral_types.id
        FROM deferral_types
        INNER JOIN phases ON deferral_types.phase_id = phases.id
        LEFT OUTER JOIN phase_durations ON phase_durations.phase_id = phases.id
        WHERE (
          (phases.active = 1)
          AND (phase_durations.level_id = ?)
        )
      )", enrollment.level_id]
    end
  end
end
