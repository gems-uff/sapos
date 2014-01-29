# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Phase < ActiveRecord::Base
  attr_accessible :name, :is_language
  has_many :accomplishments, :dependent => :restrict
  has_many :enrollments, :through => :accomplishments
  has_many :phase_durations, :dependent => :destroy
  has_many :levels, :through => :phase_durations
  has_many :deferral_type, :dependent => :restrict

  has_paper_trail
  
  validates :name, :presence => true, :uniqueness => true

  def to_label
  	"#{self.name}"
  end

  def self.find_all_for_enrollment(enrollment)
    return [] if enrollment.nil?
    ["phases.id IN (
      SELECT phases.id
      FROM phases
      LEFT OUTER JOIN phase_durations
      ON phase_durations.phase_id = phases.id
      WHERE phase_durations.level_id = ?
    )", enrollment.level_id]
  end

end
