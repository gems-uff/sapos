# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module DeferralsHelper
  @@config = YAML::load_file("#{Rails.root}/config/properties.yml")    
  @@range = @@config["scholarship_year_range"] 
  
  def approval_date_form_column(record,options)
    date_select :record, :approval_date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
         :include_blank => true,
         :default => nil,
    }.merge(options)
  end

  def valid_until_column(record, column)
    admission_date = record.enrollment.admission_date

    durations = record.deferral_type.phase.phase_durations
    phase_duration = durations.select { |duration| duration.level_id == record.enrollment.level.id}[0]
    phase_duration_semesters = phase_duration.deadline_semesters
    phase_duration_months = phase_duration.deadline_months
    phase_duration_days = phase_duration.deadline_days

    deferral_duration_semesters = record.deferral_type.duration_semesters
    deferral_duration_months = record.deferral_type.duration_months
    deferral_duration_days = record.deferral_type.duration_days

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
      valid_date = total_duration_months.months.since(valid_date)
    end

    if total_duration_days != 0
      valid_date = total_duration_days.days.since(valid_date)
    end

    valid_date
  end
end