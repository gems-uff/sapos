# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module ScholarshipDurationsHelper    
  include PdfHelper
  include ScholarshipDurationsPdfHelper 
  @@config = YAML::load_file("#{Rails.root}/config/properties.yml")    
  @@range = @@config["scholarship_year_range"]    
      
  def cancel_date_form_column(record,options)     
    date_select :record, :cancel_date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
         :include_blank => true,
         :default => nil
    }.merge(options)
  end
  
  def scholarship_duration_start_date_form_column(record,options)                
    date_select :record, :start_date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
    }.merge(options)
  end
  
  def scholarship_duration_end_date_form_column(record, options)
    date_select :record, :end_date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
         :include_blank => true,
         :default => nil,
    }.merge(options), {:class => "end_date-input"}
  end 

  def scholarship_suspension_start_date_form_column(record,options)                
    date_select(:record, :start_date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
         :include_blank => true,
         :default => nil,
    }.merge(options), {:class => "replace-date-input"}) +
    hidden_field(:record, :start_date, options)
  end
  
  def scholarship_suspension_end_date_form_column(record, options)
    date_select(:record, :end_date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
         :include_blank => true,
         :default => nil,
    }.merge(options), {:class => "replace-date-input"}) +
    hidden_field(:record, :end_date, options)
  end  
   
  
  def start_date_search_column(record,options)                
    local_options = {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
         :include_blank => true,
         :default => nil,
         :prefix => options[:name]
    }
    
    select_date record[:start_date], options.merge(local_options)
  end 
  
  def end_date_search_column(record,options)                
    local_options = {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
         :include_blank => true,
         :default => nil,
         :prefix => options[:name]
    }
    
    select_date record[:start_date], options.merge(local_options)
  end 
  
  def cancel_date_search_column(record,options)                
    local_options = {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
         :include_blank => true,
         :default => nil,
         :prefix => options[:name]
    }
    
    select_date record[:start_date], options.merge(local_options)
  end

  def adviser_search_column(record,options)
    local_options = {
        :include_blank => true,
        :class => "text-input"
        
    }
    record_select_field :adviser, Professor.new, options.merge(local_options)
  end

  def sponsors_search_column(record,options)
    local_options = {
        :include_blank => true
    }

    select_tag record[:sponsor], options_from_collection_for_select(Sponsor.order("name"), "id", "name"), options.merge(local_options)
  end

  def scholarship_types_search_column(record,options)
    local_options = {
        :include_blank => true
    }

    select_tag record[:scholarship_types], options_from_collection_for_select(ScholarshipType.order("name"), "id", "name"), options.merge(local_options)
  end

  def active_search_column(record,options)
    select_tag(record[:active], options_for_select([["Todas","all"],["Ativas","active"],["Inativas","not_active"]]), options)
  end

  def level_search_column(record,options)
    local_options = {
        :include_blank => true
    }

    select_tag record[:level], options_from_collection_for_select(Level.order("name"), "id", "name"), options.merge(local_options)
  end

end
