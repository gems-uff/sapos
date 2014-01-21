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

  def scholarship_timeline_show_column(record, column)
    block = "<div class='timeline' id='scholarship_timeline_#{record.id}'></div>
      <div class='timecaption'>
        <span class='scholarship_desc caption_desc'> #{I18n.t('activerecord.attributes.scholarship.scholarship_caption')} </span>
        <span class='end_date_desc caption_desc'> #{I18n.t('activerecord.attributes.scholarship.end_date_caption')} </span>
        <span class='cancel_date_desc caption_desc'> #{I18n.t('activerecord.attributes.scholarship.cancel_date_caption')} </span>
      </div>
    "
    block += "<script>
      var events_#{record.id} = ["
    record.scholarship_durations.each do |sd|
      last_date = sd.cancel_date.nil? ? sd.end_date : sd.cancel_date
      color = sd.cancel_date.nil? ? '#00AA00' : '#AA0000'
      extra_text = " | #{I18n.t('activerecord.attributes.scholarship.end_date_tip')}: #{I18n.localize(sd.end_date, :format => :monthyear2)}}" unless sd.cancel_date.nil?
      block += "{
        dates: [
          new Date(#{sd.start_date.year}, #{sd.start_date.month - 1}, #{sd.start_date.day}),
          new Date(#{last_date.year}, #{last_date.month - 1}, #{last_date.day})
        ],
        title: '#{sd.enrollment.to_label}: #{I18n.localize(sd.start_date, :format => :monthyear2)} - #{I18n.localize(last_date, :format => :monthyear2)}#{extra_text}',
        attrs: {
          fill: '#{color}',
          stroke: '#{color}'
        }
      },"
    end

    if record.end_date.nil? 
      last_date = (Date.today + 100.years)
      last_date_text = I18n.t('activerecord.attributes.scholarship.present')
    else
      last_date = record.end_date
      last_date_text = I18n.localize(record.end_date, :format => :monthyear2)
    end
    block += "{
      dates: [
        new Date(#{record.start_date.year}, #{record.start_date.month - 1}, #{record.start_date.day}),
        new Date(#{last_date.year}, #{last_date.month - 1}, #{last_date.day})
      ],
      title: '#{record.scholarship_number}: #{I18n.localize(record.start_date, :format => :monthyear2)} - #{last_date_text}'
    }];
    "

    last_date += 1.month
    start_date = record.start_date - 1.month

    days = [700, (last_date - start_date).to_i].min

    block += "
        var timeline = new Chronoline(document.getElementById('scholarship_timeline_#{record.id}'), events_#{record.id},
          {animated: true, 
          draggable: true,
          visibleSpan:  DAY_IN_MILLISECONDS * #{days},
          fitVisibleSpan: false, 
          labelFormat: '',
          markToday: false,
          eventHeigh: 3,
          topMargin: 0,
          startDate: new Date(#{start_date.year}, #{start_date.month - 1}, #{start_date.day}),
          endDate: new Date(#{last_date.year}, #{last_date.month - 1}, #{last_date.day}),
          floatingSubLabels: false,
          scrollLeft: prevSemester,
          scrollRight: nextSemester
        });
      "

    block += "</script>"
    block.html_safe
  end
end