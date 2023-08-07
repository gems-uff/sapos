# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Helper for Scholarship Durations
module ScholarshipDurationsHelper
  include PdfHelper
  include ScholarshipDurationsPdfHelper

  def scholarship_duration_cancel_date_form_column(record, options)
    scholarship_month_year_widget record, options, :cancel_date
  end

  def scholarship_duration_start_date_form_column(record, options)
    scholarship_month_year_widget record, options, :start_date
  end

  def scholarship_duration_end_date_form_column(record, options)
    scholarship_month_year_widget record, options, :end_date,
                                  select_options: { class: "end_date-input" }
  end

  def scholarship_suspension_start_date_form_column(record, options)
    scholarship_month_year_widget(
      record, options, :start_date, required: false, force_send: true
    )
  end

  def scholarship_suspension_end_date_form_column(record, options)
    scholarship_month_year_widget(
      record, options, :end_date, required: false, force_send: true
    )
  end

  def start_date_search_column(record, options)
    scholarship_month_year_widget(
      record, options, :start_date, required: false, multiparameter: false,
                                    date_options: { prefix: options[:name] }
    )
  end

  def end_date_search_column(record, options)
    scholarship_month_year_widget(
      record, options, :end_date, required: false, multiparameter: false,
                                  date_options: { prefix: options[:name] }
    )
  end

  def cancel_date_search_column(record, options)
    scholarship_month_year_widget(
      record, options, :cancel_date, required: false, multiparameter: false,
                                     date_options: { prefix: options[:name] }
    )
  end

  def adviser_search_column(record, options)
    local_options = {
        include_blank: true,
    }
    record_select_field :adviser, Professor.new, options.merge(local_options)
  end

  def sponsors_search_column(record, options)
    local_options = {
        include_blank: true
    }

    select_tag(
      record[:sponsor],
      options_from_collection_for_select(Sponsor.order("name"), "id", "name"),
      options.merge(local_options)
    )
  end

  def scholarship_types_search_column(record, options)
    local_options = {
        include_blank: true
    }

    select_tag(
      record[:scholarship_types],
      options_from_collection_for_select(ScholarshipType.order("name"), "id", "name"),
      options.merge(local_options)
    )
  end

  def active_search_column(record, options)
    select_tag(
      record[:active],
      options_for_select([["Todas", "all"], ["Ativas", "active"], ["Inativas", "not_active"]]),
      options
    )
  end

  def level_search_column(record, options)
    local_options = {
        include_blank: true
    }

    select_tag(
      record[:level],
      options_from_collection_for_select(Level.order("name"), "id", "name"),
      options.merge(local_options)
    )
  end
end
