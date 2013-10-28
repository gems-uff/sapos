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

  def valid_until
    admission_date = enrollment.admission_date

    durations = deferral_type.phase.phase_durations
    phase_duration = durations.select { |duration| duration.level_id == enrollment.level.id}[0]

    phase_duration_semesters = phase_duration.deadline_semesters
    phase_duration_months = phase_duration.deadline_months
    phase_duration_days = phase_duration.deadline_days

    deferral_duration_semesters = deferral_type.duration_semesters
    deferral_duration_months = deferral_type.duration_months
    deferral_duration_days = deferral_type.duration_days

    total_duration_semesters = phase_duration_semesters + deferral_duration_semesters
    total_duration_months = phase_duration_months + deferral_duration_months
    total_duration_days = phase_duration_days + deferral_duration_days

    valid_date = admission_date

    if total_duration_semesters != 0
      valid_date = (12 * (total_duration_semesters / 2)).months.since(valid_date)
      valid_date = valid_date.month == 3 ? 
        (5 * (total_duration_semesters % 2)).months.since(valid_date) : 
        (7 * (total_duration_semesters % 2)).months.since(valid_date)
      valid_date = valid_date - 1
    end

    if total_duration_months != 0
      valid_date = total_duration_months.months.since(valid_date).end_of_month
    end

    if total_duration_days != 0
      valid_date = total_duration_days.days.since(valid_date)
    end

    valid_date.strftime('%d/%m/%Y')
  end

end
