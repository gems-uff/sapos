# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module ScholarshipsHelper
  include PdfHelper
  include ScholarshipsPdfHelper

  @@config = YAML::load_file("#{Rails.root}/config/properties.yml")    
  @@range = @@config["scholarship_year_range"]    
  
  def start_date_form_column(record,options)                
    date_select :record, :start_date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range
    }    
  end
  
  def start_date_search_column(record,options)                
    local_options = {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
         :include_blank => true,
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
         :prefix => options[:name]
    }
    
    select_date record[:end_date], options.merge(local_options)
  end    
  
  def end_date_form_column(record,options)    
    date_select :record, :end_date, {
         :discard_day => true,
         :start_year => Time.now.year - @@range,
         :end_year => Time.now.year + @@range,
         :include_blank => true
    }        
  end

  def available_search_column(record, options)

    local_options = {
        :include_blank => true
    }

    day_html_options = {
        :name => "search[available][day]"
    }
    month_html_options = {
        :name => "search[available][month]"
    }
    year_html_options = {
        :name => "search[available][year]"
    }

    html = check_box_tag "search[available][use]", "yes", false, :style => "vertical-align: sub;"
    html += label_tag "search[available][use]", I18n.t("activerecord.attributes.scholarship.available_label"), :style => "margin: 0 15px;"
    #html = label_tag(:accomplishments_date, I18n.t("activerecord.attributes.enrollment.delayed_phase_date"), :style => "margin: 0px 15px") 
    #html += select_day(Date.today.day, local_options, day_html_options) 
    html += select_month(Date.today.month, local_options, month_html_options)
    html += select_year(Date.today.year, local_options, year_html_options)
    html
  end
end