# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module Admissions::AdmissionProcessesHelper
  include PdfHelper
  include Admissions::AdmissionProcessesPdfHelper

  def admission_date_form_column(record, options)
    month_year_widget(record, options, :admission_date)
  end

  def simple_id_column(record, column)
    link_to record.simple_id(closed_behavior: :optional_show),
      admission_url(record.simple_id)
  end

  def year_column(record, column)
    record.year.to_s
  end

  def edit_date_column(record, column)
    record.max_edit_date
  end

  def admission_applications_show_column(record, column)
    render partial: "admission_applications_show", locals: {
      record: record, column: column
    }
  end
end
