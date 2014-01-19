# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Deferral < ActiveRecord::Base
  belongs_to :enrollment
  belongs_to :deferral_type

  has_paper_trail

  validates :enrollment, :presence => true
  validates :enrollment_id, :uniqueness => {:scope => :deferral_type_id, :message => :enrollment_and_deferral_uniqueness}
  validates :deferral_type, :presence => true

  def to_label
    "#{deferral_type.name}" unless deferral_type.nil?    
  end

  def total_time_with_deferrals
    durations = deferral_type.phase.phase_durations
    phase_duration = durations.select { |duration| duration.level_id == enrollment.level.id}[0]

    total_time = phase_duration.duration

    deferrals = enrollment.deferrals.select { |deferral| deferral.deferral_type.phase == deferral_type.phase}
    for deferral in deferrals
      if approval_date >= deferral.approval_date
        deferral_duration = deferral.deferral_type.duration
        (total_time.keys | deferral_duration.keys).each do |key|
          total_time[key] += deferral_duration[key].to_i
        end
      end
    end

    total_time
  end

  def valid_until
    total_time = deferral_type.phase.calculate_total_deferral_time_for_phase_until_date(enrollment, approval_date)
    deferral_type.phase.calculate_end_date(enrollment.admission_date, total_time[:semesters], total_time[:months], total_time[:days]).strftime('%d/%m/%Y')
  end
end
