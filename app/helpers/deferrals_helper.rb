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

  #TODO: remove current deferraltype if enrollment was changed
  def options_for_association_conditions(association)
    if association.name == :deferral_type
      if @record.enrollment.nil? 
        super
      else
        level_id = @record.enrollment.level_id
        ["deferral_types.id IN (
          SELECT deferral_types.id
          FROM deferral_types
          INNER JOIN phases ON deferral_types.phase_id = phases.id 
          LEFT OUTER JOIN phase_durations ON phase_durations.phase_id = phases.id
          WHERE phase_durations.level_id = ?
        )", level_id]
      end

    else
      super
    end
  end
end