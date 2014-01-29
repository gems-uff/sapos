# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Accomplishment < ActiveRecord::Base
  belongs_to :enrollment
  belongs_to :phase

  has_paper_trail

  validates :enrollment, :presence => true
  validates :enrollment_id, :uniqueness => {:scope => :phase_id, :message => :accomplishment_enrollment_uniqueness}
  validates :phase, :presence => true

  validate :enrollment_level

  def to_label
    "#{phase.name}"    
  end
  

  def enrollment_level
    return if enrollment.nil?
    return if phase.nil?

    unless phase.levels.include? enrollment.level
      errors.add(:enrollment, I18n.translate("activerecord.errors.models.accomplishment.enrollment_level")) 
    end
  end
end
