# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Phase < ActiveRecord::Base
  has_many :accomplishments, :dependent => :restrict_with_exception
  has_many :enrollments, :through => :accomplishments
  has_many :phase_durations, :dependent => :destroy
  has_many :levels, :through => :phase_durations
  has_many :deferral_type, :dependent => :restrict_with_exception
  has_many :phase_completions, :dependent => :destroy

  has_paper_trail
  
  validates :name, :presence => true, :uniqueness => true

  after_save :create_phase_completions

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

  def total_duration(enrollment, options={})
    date ||= options[:until_date]

    total_time = phase_durations.select { |duration| duration.level_id == enrollment.level.id}[0].duration
    deferrals = enrollment.deferrals.select { |deferral| deferral.deferral_type.phase == self}
    deferrals.each do |deferral|
      if date.nil? or date >= deferral.approval_date
        deferral_duration = deferral.deferral_type.duration
        (total_time.keys | deferral_duration.keys).each do |key|
          total_time[key] += deferral_duration[key].to_i
        end
      end
    end
    if self.extend_on_hold
      enrollment.enrollment_holds.each do |hold|
        if date.nil? or date >= hold.start_date
          total_time[:semesters] += hold.number_of_semesters
        end
      end
    end

    total_time
  end

  def create_phase_completions
    PhaseDuration.where(:phase_id => id).each do |phase_duration|
      phase_duration.create_phase_completions
    end
  end
end
