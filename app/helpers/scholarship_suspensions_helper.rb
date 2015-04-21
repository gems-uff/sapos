# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module ScholarshipSuspensionsHelper
  @@config = YAML::load_file("#{Rails.root}/config/properties.yml")    
  @@range = @@config["scholarship_year_range"]    
      
  def start_date_form_column(record,options)                
    date_select :record, :start_date, {
      :discard_day => true,
      :start_year => Time.now.year - @@range,
      :end_year => Time.now.year + @@range,
    }.merge(options)
  end
  
  def end_date_form_column(record, options)
    date_select :record, :end_date, {
      :discard_day => true,
      :start_year => Time.now.year - @@range,
      :end_year => Time.now.year + @@range,
      :include_blank => true,
      :default => nil,
    }.merge(options), {:class => "end_date-input"}
  end  
end