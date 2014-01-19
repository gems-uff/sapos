# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Phase < ActiveRecord::Base
  attr_accessible :name, :is_language
  has_many :accomplishments, :dependent => :restrict
  has_many :enrollments, :through => :accomplishments
  has_many :phase_durations, :dependent => :destroy
  has_many :levels, :through => :phase_durations
  has_many :deferral_type, :dependent => :restrict
  has_many :phase_completions, :dependent => :destroy

  has_paper_trail
  
  validates :name, :presence => true, :uniqueness => true

  def to_label
  	"#{self.name}"
  end

  def calculate_total_deferral_time_for_phase_until_date(enrollment, date)
    total_time = phase_durations.select { |duration| duration.level_id == enrollment.level.id}[0].duration

    deferrals = enrollment.deferrals.select { |deferral| deferral.deferral_type.phase == self}
    for deferral in deferrals
      if date >= deferral.approval_date
        deferral_duration = deferral.deferral_type.duration
        (total_time.keys | deferral_duration.keys).each do |key|
          total_time[key] += deferral_duration[key].to_i
        end
      end
    end

    total_time
  end

  def calculate_end_date(date, total_semesters, total_months, total_days)
    if total_semesters != 0
      semester_months = (12 * (total_semesters / 2)) + ((date.month == 3 ? 5 : 7) * (total_semesters % 2)) - 1
      date = semester_months.months.since(date).end_of_month
    end

    total_days.days.since(total_months.months.since(date).end_of_month)
  end
end
