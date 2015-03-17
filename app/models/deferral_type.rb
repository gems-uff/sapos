# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class DeferralType < ActiveRecord::Base
  belongs_to :phase
  has_many :deferrals, :dependent => :restrict_with_exception

  has_paper_trail

  validates :name, :presence => true
  validates :phase, :presence => true

  validate :duration_validation

  def duration_validation
    if (([0,nil].include?(self.duration_semesters)) && ([0,nil].include?(self.duration_months)) && ([0,nil].include?(self.duration_days)))
      errors.add(:duration, I18n.t("activerecord.errors.models.deferral_type.blank_duration"))
    end
  end

  def to_label
    "#{self.name}"
  end

  def duration
    {:semesters => self.duration_semesters, :months => self.duration_months, :days => self.duration_days}
  end

  def self.find_all_for_enrollment(enrollment)
    return [] if enrollment.nil?
    ["deferral_types.id IN (
      SELECT deferral_types.id
      FROM deferral_types
      INNER JOIN phases ON deferral_types.phase_id = phases.id 
      LEFT OUTER JOIN phase_durations ON phase_durations.phase_id = phases.id
      WHERE phase_durations.level_id = ?
    )", enrollment.level_id]
  end
end
