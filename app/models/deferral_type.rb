# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class DeferralType < ActiveRecord::Base
  attr_accessible :name
  belongs_to :phase
  has_many :deferrals

  validates :name, :presence => true
  validates :phase, :presence => true

  validate :duration_validation

  def duration_validation
    if (([0,nil].include?(self.duration_semesters)) && ([0,nil].include?(self.duration_months)) && ([0,nil].include?(self.duration_days)))
      errors.add(:duration, I18n.t("activerecord.errors.models.deferral_type.blank_duration"))
    end
  end
end
