#encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class PhaseDuration < ActiveRecord::Base
  belongs_to :phase
  belongs_to :level

  has_paper_trail

  validates :phase, :presence => true
  validates :level, :presence => true

  validate :deadline_validation

  def to_label
    "#{deadline_semesters} períodos, #{deadline_months} meses e #{deadline_days} dias"
  end

  def deadline_validation
    if (([0,nil].include?(self.deadline_semesters)) && ([0,nil].include?(self.deadline_months)) && ([0,nil].include?(self.deadline_days)))
      errors.add(:deadline, I18n.t("activerecord.errors.models.phase_duration.blank_deadline"))
    end
  end
end
