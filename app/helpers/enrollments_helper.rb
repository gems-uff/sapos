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
    puts record.dismissal
    puts record.accomplishments
    puts record.deferrals
    if record.dismissal or record.accomplishments.count > 0 or record.deferrals.count > 0
      if record.level
        return record.level.name
      end
    end
    selected = record.level.nil? ? nil : record.level.id 
    select :record, :level, options_for_select(Level.all.map {|level| [level.name, level.id]}, :selected => selected) 
  end

#  TODO , quando se edita uma matrícula, esta retorna todas as Realizações de etapa que o nível da matrícula
#  porém o evento de on change do select de nível não está sendo possível por causa do javascript (pesquisar mais a fundo)
#  métodos envolvidos "active_scaffold.js" -> render_form_field & replace_html
  def options_for_association_conditions(association)
    if association.name == :phase
      enrollment_id = params[:id]
      enrollment = Enrollment.find_by_id(enrollment_id)

      level_id = enrollment.nil? ? params[:value] : enrollment.level_id #recupera level_id vindo do parâmetro de atualização

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

    body += "<table class=\"listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>Nome do Orientador</td>
                <th>Matrícula do Orientador</td>
              </tr>
            </thead>"
            
    body += "<tbody class=\"records\">"

    record.advisements.each do |advisement|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      if advisement.main_advisor
        body += "<tr class=\"record #{tr_class}\">
                  <td><strong>#{advisement.professor.name}</strong></td>
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

    body += "<table class=\"listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>Etapa</td>
                <th>Data de Conclusão</td>
                <th>Observação</td>
              </tr>
            </thead>"
            
    body += "<tbody class=\"records\">"

    record.accomplishments.each do |accomplishment|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      body += "<tr class=\"record #{tr_class}\">
                <td>#{accomplishment.phase.name}</td>
                <td>#{accomplishment.conclusion_date}</td>
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

    body += "<table class=\"listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>Data de Aprovação</td>
                <th>Tipo de Prorrogação</td>
                <th>Observação</td>
              </tr>
            </thead>"
    
    body += "<tbody class=\"records\">"

    record.deferrals.each do |deferral|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      body += "<tr class=\"record #{tr_class}\">
                <td>#{deferral.approval_date}</td>
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

    body += "<table class=\"listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>Número da Bolsa</td>
                <th>Data de início</td>
                <th>Data limite de concessão</td>
                <th>Data de encerramento</td>
                <th>Observação</td>
              </tr>
            </thead>"

    body += "<tbody class=\"records\">"
            
    record.scholarships.each do |scholarship|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      body += "<tr class=\"record #{tr_class}\">
                <td>#{scholarship.scholarship_number}</td>
                <td>#{scholarship.start_date}</td>
                <td>#{scholarship.scholarship_durations.where(:cancel_date => nil).empty? ? "-" : scholarship.scholarship_durations.where(:cancel_date => nil).last.end_date}</td>
                <td>#{scholarship.end_date}</td>
                <td>#{scholarship.obs}</td>
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

    body += "<table class=\"listed-records-table\">"
    
    body += "<thead>
              <tr>
                <th>Turma</td>
                <th>Situação</td>
                <th>Nota</td>
                <th>Reprovado por falta</td>
                <th>Observação</td>
              </tr>
            </thead>"
            
    body += "<tbody class=\"records\">"

    record.class_enrollments.each do |class_enrollment|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      grade = (class_enrollment.grade / 10.0) rescue 0

      body += "<tr class=\"record #{tr_class}\">
                <td>#{class_enrollment.course_class.name}</td>
                <td>#{class_enrollment.situation}</td>
                <td>#{grade}</td>"

      if class_enrollment.attendance_to_label == "N"                                                                                       
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
end
