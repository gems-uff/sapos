# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ScholarshipDurationsController < ApplicationController
  authorize_resource

  active_scaffold :scholarship_duration do |config|
    config.action_links.add "to_pdf",
      label: I18n.t("active_scaffold.to_pdf"),
      page: true,
      type: :collection,
      parameters: { format: :pdf }

    # Enables advanced search A.K.A FieldSearch
    config.actions.swap :search, :field_search

    # virtual columns for advanced search
    config.columns.add :adviser, :sponsors, :scholarship_types, :active, :level, :suspended

    config.field_search.columns = [
      :scholarship, :start_date, :end_date, :cancel_date, :enrollment,
      :adviser, :sponsors, :scholarship_types, :level, :active, :suspended
    ]
    config.columns[:start_date].search_sql = "scholarship_durations.start_date"
    config.columns[:end_date].search_sql = "scholarship_durations.end_date"
    config.columns[:cancel_date].search_sql =
      "scholarship_durations.cancel_date"
    config.columns[:enrollment].search_sql = "enrollments.enrollment_number"
    config.columns[:adviser].search_sql = ""
    config.columns[:sponsors].search_sql = ""
    config.columns[:scholarship_types].search_sql = ""
    config.columns[:active].search_sql = ""
    config.columns[:suspended].search_sql = ""
    config.columns[:level].search_sql = ""
    config.columns[:scholarship].search_ui = :text
    config.columns[:enrollment].search_ui = :text
    config.columns[:adviser].search_ui = :record_select

    config.list.sorting = { scholarship: "ASC" }
    config.list.columns = [
      :scholarship, :start_date, :end_date, :cancel_date, :enrollment
    ]
    config.create.label = :create_scholarship_duration_label
    config.columns = [
      :scholarship, :enrollment, :start_date, :cancel_date,
      :end_date, :obs, :scholarship_suspensions
    ]
    config.columns[:scholarship].search_sql = "scholarships.scholarship_number"
    config.columns[:scholarship].sort_by sql: "scholarships.scholarship_number"
    config.columns[:scholarship].form_ui = :record_select
    config.columns[:scholarship].update_columns = [:end_date]
    config.columns[:scholarship].send_form_on_update_column = true
    config.columns[:enrollment].form_ui = :record_select
    config.columns[:enrollment].update_columns = [:end_date]
    config.columns[:enrollment].send_form_on_update_column = true
    config.columns[:end_date].send_form_on_update_column = true
    config.columns[:start_date].options = { format: :monthyear }
    config.columns[:end_date].options = { format: :monthyear }
    config.columns[:cancel_date].options = { format: :monthyear }
    config.create.columns = [
      :scholarship, :enrollment, :start_date, :end_date, :cancel_date, :obs
    ]
    config.update.columns = [
      :scholarship, :enrollment, :start_date, :end_date, :cancel_date,
      :obs, :scholarship_suspensions
    ]

    config.actions.exclude :deleted_records
  end
  record_select per_page: 10, full_text_search: true

  def record_select_includes
    [:enrollment, :scholarship]
  end

  def self.condition_for_adviser_column(column, value, like_pattern)
    unless value.blank?
      professor_id = Advisement.arel_table[:professor_id]
      scholarship_durations_id = ScholarshipDuration.arel_table[:id]
      query = Enrollment.joins(:scholarship_durations).joins(:advisements)
        .where(professor_id.eq(value))
        .select(scholarship_durations_id)
        .to_sql

      sql = "scholarship_durations.id IN (#{query})"

      [sql]
    end
  end

  def self.condition_for_sponsors_column(column, value, like_pattern)
    unless value.blank?
      sql = "scholarship_durations.scholarship_id IN(
            SELECT scholarships.id
            FROM   scholarships
            INNER JOIN sponsors
            ON scholarships.sponsor_id = sponsors.id
            WHERE sponsors.id = ?
          )"

      [sql, value]
    end
  end


  def self.condition_for_scholarship_types_column(column, value, like_pattern)
    unless value.blank?
      sql = "scholarship_durations.scholarship_id IN (
		     SELECT scholarships.id
		     FROM   scholarships
		     WHERE  scholarships.scholarship_type_id = ?
		  )"

      [sql, value]
    end
  end

  def self.condition_for_active_column(column, value, like_pattern)
    unless value.blank?
      query_active_scholarships = "
        DATE(scholarship_durations.end_date) >= DATE(?) AND (
          scholarship_durations.cancel_date is NULL OR
          DATE(scholarship_durations.cancel_date) >= DATE(?)
        )
      "
      query_inactive_scholarships = "
        DATE(scholarship_durations.end_date) < DATE(?) OR
        DATE(scholarship_durations.cancel_date) < DATE(?)
      "
      case value
      when "active" then
        sql = query_active_scholarships
      when "not_active" then
        sql = query_inactive_scholarships
      else
        return ""
      end

      [sql, Time.now, Time.now]
    end
  end

  def self.condition_for_level_column(column, value, like_pattern)
    unless value.blank?
      ["scholarship_durations.scholarship_id IN (
      SELECT scholarships.id
      FROM   scholarships
      WHERE  scholarships.level_id = ?
    )", value]
    end
  end

  def self.condition_for_start_date_column(column, value, like_pattern)
    unless value.blank?
      month = value[:month].empty? ? 1 : value[:month]
      year = value[:year].empty? ? 1 : value[:year]

      if year != 1
        date = Date.new(year.to_i, month.to_i)

        ["#{column.search_sql.last} >= ?", date]
      end
    end
  end

  def self.condition_for_end_date_column(column, value, like_pattern)
    unless value.blank?
      month = value[:month].empty? ? 1 : value[:month]
      year = value[:year].empty? ? 1 : value[:year]

      if year != 1
        date = Date.new(year.to_i, month.to_i)

        ["#{column.search_sql.last} >= ?", date]
      end
    end
  end

  def self.condition_for_cancel_date_column(column, value, like_pattern)
    unless value.blank?
      month = value[:month].empty? ? 1 : value[:month]
      year = value[:year].empty? ? 1 : value[:year]

      if year != 1
        date = Date.new(year.to_i, month.to_i)

        ["#{column.search_sql.last} >= ?", date]
      end
    end
  end

  def self.condition_for_suspended_column(column, value, like_pattern)
    if value[:use] == "yes"
      start_month = value[:start_month].present? ? value[:start_month].to_i : 1
      start_year = value[:start_year].present? ? value[:start_year].to_i : 1

      end_month = value[:end_month].present? ? value[:end_month].to_i : 1
      end_year = value[:end_year].present? ? value[:end_year].to_i : 1

      start_dt = Date.new(start_year.to_i, start_month.to_i)
      end_dt = Date.new(end_year.to_i, end_month.to_i)

      # scholarship_durations = ScholarshipDuration.arel_table
      # scholarship_suspensions = ScholarshipSuspension.arel_table
      # scholarship_durations_id = ScholarshipDuration.arel_table[:id]

      if start_year == 1 && end_year == 1
        query = "(SELECT d.id
                FROM scholarship_durations as d
                JOIN scholarship_suspensions as s
                ON d.id = s.scholarship_duration_id
                WHERE s.active
                GROUP BY d.id)"
      elsif end_year == 1
        query = "(SELECT d.id
                FROM scholarship_durations as d
                JOIN scholarship_suspensions as s
                ON d.id = s.scholarship_duration_id
                WHERE s.active
                AND s.end_date > ?
                GROUP BY d.id)"
        query_params = [start_dt]
      elsif start_year == 1
        query = "(SELECT d.id
                FROM scholarship_durations as d
                JOIN scholarship_suspensions as s
                ON d.id = s.scholarship_duration_id
                WHERE s.active
                AND s.start_date < ?
                GROUP BY d.id)"
        query_params = [end_dt]
      else
        query = "(SELECT d.id
                FROM scholarship_durations as d
                JOIN scholarship_suspensions as s
                ON d.id = s.scholarship_duration_id
                WHERE s.active
                AND s.end_date > ?
                AND s.start_date < ?
                GROUP BY d.id)"
        query_params = [start_dt, end_dt]
      end
      ["scholarship_durations.id IN" + query, *query_params]
    end
  end

  def after_create_save(record)
    flash[:warning] = record.warning_message
  end

  def after_update_save(record)
    flash[:warning] = record.warning_message
  end

  def after_render_field(record, column)
    if column.name == :enrollment || column.name == :scholarship
      if record.enrollment.nil? && params[:parent_controller] == "enrollments"
        if params[:parent_id].nil? || params[:parent_id].empty?
          record.enrollment = Enrollment.new
        else
          record.enrollment = Enrollment.find(params[:parent_id])
        end
        hash = params[:record].slice(
          "admission_date(3i)", "admission_date(2i)", "admission_date(1i)"
        )

        record.enrollment.attributes = hash
        unless params[:record]["level"].blank?
          record.enrollment.level = Level.find(params[:record]["level"])
        end
      end
      record.update_end_date
    end
  end

  def to_pdf
    # pdf = Prawn::Document.new
    each_record_in_page { }
    scholarship_durations_list = find_page(
      sorting: active_scaffold_config.list.user.sorting
    ).items

    @scholarship_durations = scholarship_durations_list.map do |scp|
      [
        scp.scholarship[:scholarship_number],
        scp[:start_date]&.to_fs,
        scp[:end_date]&.to_fs,
        scp[:cancel_date]&.to_fs,
        scp.enrollment[:enrollment_number]
      ]
    end

    respond_to do |format|
      format.pdf do
        title = I18n.t("pdf_content.scholarship_durations.to_pdf.filename")
        send_data render_to_string,
          filename: "#{title}.pdf",
          type: "application/pdf"
      end
    end
  end

  protected
    def do_new
      super
      @record.init
    end
end
