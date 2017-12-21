# Copyright (c) Universidade Federal Fluminense (UFF).
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
  def options_for_association_conditions(association, record)
    if association.name == :deferral_type
      DeferralType::find_all_for_enrollment(record.enrollment)
    else
      super
    end
  end
end
