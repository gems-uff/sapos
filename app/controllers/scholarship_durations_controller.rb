# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ScholarshipDurationsController < ApplicationController
  active_scaffold :scholarship_duration do |config|
    config.action_links.add 'to_pdf', :label => I18n.t('active_scaffold.to_pdf'), :page => true, :type => :collection

    #Enables advanced search A.K.A FieldSearch
    config.actions.swap :search, :field_search

    #virtual columns for advanced search
    config.columns.add :adviser, :sponsors, :scholarship_types, :active, :level

    config.field_search.columns = [:scholarship, :start_date, :end_date, :cancel_date, :enrollment, :adviser, :sponsors, :scholarship_types, :level, :active]
    config.columns[:start_date].search_sql = 'scholarship_durations.start_date'
    config.columns[:end_date].search_sql = 'scholarship_durations.end_date'
    config.columns[:cancel_date].search_sql = 'scholarship_durations.cancel_date'
    config.columns[:enrollment].search_sql = 'enrollments.enrollment_number'
    config.columns[:adviser].search_sql = ''
    config.columns[:sponsors].search_sql = ''
    config.columns[:scholarship_types].search_sql = ''
    config.columns[:active].search_sql = ''
    config.columns[:level].search_sql = ''
    config.columns[:scholarship].search_ui = :text
    config.columns[:enrollment].search_ui = :text

    config.columns[:scholarship].clear_link
    config.columns[:enrollment].clear_link
    config.list.sorting = {:scholarship => 'ASC'}
    config.list.columns = [:scholarship, :start_date, :cancel_date, :end_date, :enrollment]
    config.create.label = :create_scholarship_duration_label
    config.columns = [:scholarship, :enrollment, :start_date, :cancel_date, :end_date, :obs]
    config.columns[:scholarship].search_sql = 'scholarships.scholarship_number'
    config.columns[:scholarship].sort_by :sql => 'scholarships.scholarship_number'
    config.columns[:scholarship].form_ui = :record_select
    config.columns[:enrollment].form_ui = :record_select
    config.columns[:start_date].options = {:format => :monthyear}
    config.columns[:end_date].options = {:format => :monthyear}
    config.columns[:cancel_date].options = {:format => :monthyear}
    config.create.columns = [:scholarship, :enrollment, :start_date, :end_date, :cancel_date, :obs]
    config.update.columns = [:scholarship, :enrollment, :start_date, :end_date, :cancel_date, :obs]
  end

  def self.condition_for_adviser_column(column, value, like_pattern)
    sql = "enrollments.id IN (
             SELECT adv.enrollment_id
             FROM advisements AS adv
             INNER JOIN professors
             ON professors.id = adv.professor_id
             WHERE professors.id = ?
	         )"

    [sql, value]
  end

  def self.condition_for_sponsors_column(column, value, like_pattern)
    sql = "scholarship_durations.scholarship_id IN(
            SELECT scholarships.id
            FROM   scholarships
            INNER JOIN sponsors
            ON scholarships.sponsor_id = sponsors.id
            WHERE sponsors.id = ?
          )"

    [sql, value]
  end


  def self.condition_for_scholarship_types_column(column, value, like_pattern)
    sql = "scholarships.scholarship_type_id = ?"

    [sql, value]
  end

  def self.condition_for_active_column(column, value, like_pattern)
    query_active_scholarships = "DATE(scholarship_durations.end_date) >= DATE(?) AND  (scholarship_durations.cancel_date is NULL OR DATE(scholarship_durations.cancel_date) >= DATE(?))"
    query_inactive_scholarships = "DATE(scholarship_durations.end_date) < DATE(?) OR DATE(scholarship_durations.cancel_date) < DATE(?)"
    case value
      when "active" then
        sql = query_active_scholarships
      when "not_active" then
        sql = query_inactive_scholarships
      else
        sql = ""
    end

    [sql, Time.now, Time.now]
  end

  def self.condition_for_level_column(column, value, like_pattern)
    ["scholarships.id IN (
      SELECT scholarships.id
      FROM   scholarships
      WHERE  scholarships.level_id = ?
    )", value]
  end

  def self.condition_for_start_date_column(column, value, like_pattern)
    month = value[:month].empty? ? 1 : value[:month]
    year = value[:year].empty? ? 1 : value[:year]

    if year != 1
      date = Date.new(year.to_i, month.to_i)

      ["#{column.search_sql} >= ?", date]
    end
  end

  def self.condition_for_end_date_column(column, value, like_pattern)
    month = value[:month].empty? ? 1 : value[:month]
    year = value[:year].empty? ? 1 : value[:year]

    if year != 1
      date = Date.new(year.to_i, month.to_i)

      ["#{column.search_sql} >= ?", date]
    end
  end

  def self.condition_for_cancel_date_column(column, value, like_pattern)
    month = value[:month].empty? ? 1 : value[:month]
    year = value[:year].empty? ? 1 : value[:year]

    if year != 1
      date = Date.new(year.to_i, month.to_i)

      ["#{column.search_sql} >= ?", date]
    end
  end

  def to_pdf
    pdf = Prawn::Document.new

    y_position = pdf.cursor

    pdf.image("#{Rails.root}/config/images/logoIC.jpg", :at => [455, y_position],
              :vposition => :top,
              :scale => 0.3
    )

    pdf.font("Courier", :size => 14) do
      pdf.text "Universidade Federal Fluminense
                Instituto de Computação
                Pós-Graduação"
    end

    pdf.move_down 30

    header = [["<b>Número da Bolsa</b>",
               "<b>Data de Início</b>",
               "<b>Data de Limite de Concessão</b>",
               "<b>Data de Encerramento</b>",
               "<b>Matrícula</b>"]]
    pdf.table(header, :column_widths => [108, 108, 108, 108, 108],
              :row_colors => ["BFBFBF"],
              :cell_style => {:font => "Courier",
                              :size => 10,
                              :inline_format => true,
                              :border_width => 0
              }
    )

    each_record_in_page {}
    scholarship_durations_list = find_page(:sorting => active_scaffold_config.list.user.sorting).items

    scholarship_durations = scholarship_durations_list.map do |scp|
      [
          scp.scholarship[:scholarship_number],
          scp[:start_date],
          scp[:end_date],
          scp[:cancel_date],
          scp.enrollment[:enrollment_number]
      ]
    end

    pdf.table(scholarship_durations, :column_widths => [108, 108, 108, 108, 108],
              :row_colors => ["FFFFFF", "F0F0F0"],
              :cell_style => {:font => "Courier",
                              :size => 8,
                              :inline_format => true,
                              :border_width => 0
              }
    )

    send_data(pdf.render, :filename => 'relatorio.pdf', :type => 'application/pdf')
  end

  def update_authorized?(record=nil)
    can? :update, record
  end

  def create_authorized?(record=nil)
    can? :create, record
  end

  def show_authorized?(record=nil)
    can? :read, record
  end

  def delete_authorized?(record=nil)
    can? :delete, record
  end
end 