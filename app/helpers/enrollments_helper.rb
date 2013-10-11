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
end
