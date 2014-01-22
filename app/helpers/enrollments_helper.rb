#encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module EnrollmentsHelper
  include PdfHelper
  include EnrollmentsPdfHelper

  @@config = YAML::load_file("#{Rails.root}/config/properties.yml")
  @@range = @@config["scholarship_year_range"]

  #overriding dismissal date to_label
  def dismissal_column(record, input_name)
    I18n.localize(record.dismissal.to_label.to_date, {:format => :monthyear}) unless record.dismissal.nil? or record.nil?
  end

  # display the "user_type" field as a dropdown with options
  def scholarship_durations_active_search_column(record, input_name)
    select :record, :scholarship_durations, options_for_select([["Sim", 1], ["Não", 0]]), {:include_blank => as_(:_select_)}, input_name
  end

  def active_search_column(record, input_name)
    select :record, :dismissal, options_for_select([["Sim", 1], ["Não", 0]]), {:include_blank => as_(:_select_)}, input_name
  end

  def delayed_phase_search_column(record, input_name)
    local_options = {
        :include_blank => true
    }
    select_html_options = {
        :name => "search[delayed_phase][phase]"
    }
    day_html_options = {
        :name => "search[delayed_phase][day]"
    }
    month_html_options = {
        :name => "search[delayed_phase][month]"
    }
    year_html_options = {
        :name => "search[delayed_phase][year]"
    }

    select(:record, :phases, options_for_select([["Alguma", "all"]] + Phase.all.map {|phase| [phase.name, phase.id]}), {:include_blank => as_(:_select_)}, select_html_options) + label_tag(:delayed_phase_date, I18n.t("activerecord.attributes.enrollment.delayed_phase_date"), :style => "margin: 0px 15px") +  select_day(Date.today.day, local_options, day_html_options) +  select_month(Date.today.month, local_options, month_html_options) + select_year(Date.today.year, local_options, year_html_options)
  end

  def accomplishments_search_column(record, input_name)
    local_options = {
        :include_blank => true
    }
    select_html_options = {
        :name => "search[accomplishments][phase]"
    }
    day_html_options = {
        :name => "search[accomplishments][day]"
    }
    month_html_options = {
        :name => "search[accomplishments][month]"
    }
    year_html_options = {
        :name => "search[accomplishments][year]"
    }

    select(:record, :phases, options_for_select([["Todas", "all"]] + Phase.all.map {|phase| [phase.name, phase.id]}), {:include_blank => as_(:_select_)}, select_html_options) + label_tag(:accomplishments_date, I18n.t("activerecord.attributes.enrollment.delayed_phase_date"), :style => "margin: 0px 15px") +  select_day(Date.today.day, local_options, day_html_options) +  select_month(Date.today.month, local_options, month_html_options) + select_year(Date.today.year, local_options, year_html_options)
  end

  def approval_date_form_column(record, options)
    date_select :record, :approval_date, {
        :discard_day => true,
        :start_year => Time.now.year - @@range,
        :end_year => Time.now.year + @@range,
        :include_blank => true,
        :default => nil,
    }.merge(options)
  end

  def conclusion_date_form_column(record, options)
    date_select :record, :conclusion_date, {
        :discard_day => true,
        :start_year => Time.now.year - @@range,
        :end_year => Time.now.year + @@range,
        :include_blank => true,
        :default => nil,
    }.merge(options)
  end

  def date_form_column(record, options)
    date_select :record, :date, {
        :discard_day => true,
        :start_year => Time.now.year - @@range,
        :end_year => Time.now.year + @@range,
        :include_blank => true,
        :default => nil,
    }.merge(options)
  end

  def cancel_date_form_column(record, options)
    date_select :record, :cancel_date, {
        :discard_day => true,
        :start_year => Time.now.year - @@range,
        :end_year => Time.now.year + @@range,
        :include_blank => true,
        :default => nil,
    }.merge(options)
  end

  def start_date_form_column(record, options)
    date_select :record, :start_date, {
        :discard_day => true,
        :start_year => Time.now.year - @@range,
        :end_year => Time.now.year + @@range
    }.merge(options)
  end

  def end_date_form_column(record, options)
    date_select :record, :end_date, {
        :discard_day => true,
        :start_year => Time.now.year - @@range,
        :end_year => Time.now.year + @@range
    }.merge(options)
  end

  def admission_date_form_column(record,options)
    date_select :record, :admission_date, {
        :discard_day => true,
        :start_year => Time.now.year - @@range,
        :end_year => Time.now.year + @@range
    }
  end


  def admission_date_search_column(record,options)
    local_options = {
        :discard_day => true,
        :start_year => Time.now.year - @@range,
        :end_year => Time.now.year + @@range,
        :include_blank => true,
        :prefix => options[:name]
    }

    select_date record[:admission_date], options.merge(local_options)
  end


  def level_form_column(record, options)
    if record.dismissal or record.accomplishments.count > 0 or record.deferrals.count > 0
      if record.level
        return record.level.name
      end
    end
    selected = record.level.nil? ? nil : record.level.id 
    scope ||= nil 
    column = active_scaffold_config.columns[:level]
    active_scaffold_input_select column, options
    #select :record, :level, options_for_select(Level.all.map {|level| [level.name, level.id]}, :selected => selected) 
  end

  #TODO: remove current accomplishments if level was changed
  def options_for_association_conditions(association)
    if association.name == :phase
      enrollment_id = params[:id]
      enrollment = Enrollment.find_by_id(enrollment_id)
      #level_id = enrollment.nil? ? params[:value] : enrollment.level_id #recupera level_id vindo do parâmetro de atualização
      level_id = @record.enrollment.nil? ? params[:value] : @record.enrollment.level_id
      ["phases.id IN (
       SELECT phases.id
       FROM phases
       LEFT OUTER JOIN phase_durations
       ON phase_durations.phase_id = phases.id
       WHERE phase_durations.level_id = ?
       )", level_id]
    else
      super
    end
  end

  def enrollment_advisements_show_column(record, column)
    return "-" if record.advisements.empty? 
    
    body = ""
    count = 0

    body += "<table class=\"showtable listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>#{I18n.t('activerecord.attributes.advisement.professor')}</th>
                <th>#{I18n.t('activerecord.attributes.advisement.professor_enrollment_number')}</th>
              </tr>
            </thead>"
            
    body += "<tbody class=\"records\">"

    record.advisements.each do |advisement|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      if advisement.main_advisor
        body += "<tr class=\"record #{tr_class}\">
                  <td title='#{I18n.t('activerecord.attributes.advisement.main_advisor')}'><strong>#{advisement.professor.name}*</strong></td>
                  <td><strong>#{advisement.professor.enrollment_number}</strong></td>
                </tr>"
      else
        body += "<tr class=\"record #{tr_class}\">
                  <td>#{advisement.professor.name}</td>
                  <td>#{advisement.professor.enrollment_number}</td>
                </tr>"
      end
    end

    body += "</tbody>"
    body += "</table>"
    body.html_safe
  end

  def enrollment_accomplishments_show_column(record, column)
    return "-" if record.accomplishments.empty?

    body = ""
    count = 0

    body += "<table class=\"showtable listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>#{I18n.t('activerecord.attributes.accomplishment.phase')}</th>
                <th>#{I18n.t('activerecord.attributes.accomplishment.conclusion_date')}</th>
                <th>#{I18n.t('activerecord.attributes.accomplishment.obs')}</th>
              </tr>
            </thead>"
            
    body += "<tbody class=\"records\">"

    record.accomplishments.each do |accomplishment|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      body += "<tr class=\"record #{tr_class}\">
                <td>#{accomplishment.phase.name}</td>
                <td>#{I18n.localize(accomplishment.conclusion_date, :format=>:monthyear2)}</td>
                <td>#{accomplishment.obs}</td>
              </tr>"
    end

    body += "</tbody>"
    body += "</table>"
    body.html_safe
  end

  def enrollment_deferrals_show_column(record, column)
    return "-" if record.deferrals.empty?
    
    body = ""
    count = 0

    body += "<table class=\"showtable listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>#{I18n.t('activerecord.attributes.deferral.approval_date')}</th>
                <th>#{I18n.t('activerecord.attributes.deferral.deferral_type')}</th>
                <th>#{I18n.t('activerecord.attributes.deferral.obs')}</th>
              </tr>
            </thead>"
    
    body += "<tbody class=\"records\">"

    record.deferrals.each do |deferral|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      body += "<tr class=\"record #{tr_class}\">
                <td>#{I18n.localize(deferral.approval_date, :format => :monthyear2)}</td>
                <td>#{deferral.deferral_type.name}</td>
                <td>#{deferral.obs}</td>
              </tr>"
    end

    body += "</tbody>"
    body += "</table>"
    body.html_safe
  end

  def enrollment_scholarship_durations_show_column(record, column)
    return "-" if record.scholarships.empty?
    
    body = ""
    count = 0

    body += "<table class=\"showtable listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>#{I18n.t('activerecord.attributes.scholarship.scholarship_number')}</th>
                <th>#{I18n.t('activerecord.attributes.scholarship_duration.start_date')}</th>
                <th>#{I18n.t('activerecord.attributes.scholarship_duration.end_date')}</th>
                <th>#{I18n.t('activerecord.attributes.scholarship_duration.cancel_date')}</th>
                <th>#{I18n.t('activerecord.attributes.scholarship_duration.obs')}</th>
              </tr>
            </thead>"

    body += "<tbody class=\"records\">"
    nilvalue = '-'
    record.scholarship_durations.each do |sd|
      count += 1
      tr_class = count.even? ? "even-record" : ""
      end_date = sd.end_date.nil? ? nilvalue : I18n.localize(sd.end_date, :format => :monthyear2)
      cancel_date = sd.cancel_date.nil? ? nilvalue : I18n.localize(sd.cancel_date, :format => :monthyear2)
      
      body += "<tr class=\"record #{tr_class}\">
                <td title='#{sd.scholarship.sponsor.name}'>#{sd.scholarship.scholarship_number}</td>
                <td>#{I18n.localize(sd.start_date, :format => :monthyear2)}</td>
                <td>#{end_date}</td>
                <td>#{cancel_date}</td>
                <td>#{sd.obs}</td>
              </tr>"
    end

    body += "</tbody>"
    body += "</table>"
    body.html_safe
  end

  def enrollment_class_enrollments_show_column(record, column)
    return "-" if record.class_enrollments.empty?
    
    body = ""
    count = 0

    body += "<table class=\"showtable listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>#{I18n.t('activerecord.models.course.one')}</th>
                <th>#{I18n.t('activerecord.attributes.class_enrollment.situation')}</th>
                <th>#{I18n.t('activerecord.attributes.class_enrollment.grade')}</th>
                <th>#{I18n.t('activerecord.attributes.class_enrollment.disapproved_by_absence')}</th>
                <th>#{I18n.t('activerecord.attributes.class_enrollment.obs')}</th>
              </tr>
            </thead>"
            
    body += "<tbody class=\"records\">"

    record.class_enrollments.each do |class_enrollment|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      grade = (class_enrollment.grade / 10.0) rescue 0
      body += "<tr class=\"record #{tr_class}\">
                <td>#{class_enrollment.course_class.course.name}</td>
                <td>#{class_enrollment.situation}</td>
                <td>#{grade}</td>"

      if class_enrollment.attendance_to_label == "I"                                                                                       
        body += "<td>Sim</td>"
      else
        body += "<td>Não</td>"
      end

      body += "<td>#{class_enrollment.obs}</td>
             </tr>"
    end

    body += "</tbody>"
    body += "</table>"
    body.html_safe
  end

  def enrollment_thesis_defense_committee_participations_show_column(record, column)
    return "-" if record.thesis_defense_committee_participations.empty?
    
    body = ""
    count = 0

    body += "<table class=\"showtable listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>#{I18n.t('activerecord.attributes.professor.name')}</th>
                <th>#{I18n.t('activerecord.attributes.professor.institution')}</th>
              </tr>
            </thead>"

    body += "<tbody class=\"records\">"
            
    record.thesis_defense_committee_professors.each do |professor|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      body += "<tr class=\"record #{tr_class}\">
                <td>#{professor.name}</td>
                <td>#{rescue_blank_text(professor.institution, :method_call => :name)}</td>
              </tr>"
    end

    body += "</tbody>"
    body += "</table>"
    body.html_safe
  end
end
