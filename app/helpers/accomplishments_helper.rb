# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module AccomplishmentsHelper
  @@config = YAML::load_file("#{Rails.root}/config/properties.yml")    
  @@range = @@config["scholarship_year_range"] 
  
  def conclusion_date_form_column(record,options)    
    date_select :record, :conclusion_date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range
       }.merge(options)
  end

  #TODO: remove current accomplishments and current deferral_type if level was changed
  def options_for_association_conditions(association)
    if association.name == :phase
      Phase::find_all_for_enrollment(@record.enrollment)
    else
      super
    end
  end
end