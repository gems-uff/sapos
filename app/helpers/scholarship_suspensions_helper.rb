# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Helper for Scholarship Suspensions
module ScholarshipSuspensionsHelper
  def start_date_form_column(record, options)
    month_year_widget(record, options, :start_date)
  end

  def end_date_form_column(record, options)
    month_year_widget(
      record, options, :end_date,
      select_options: { class: "end_date-input" }, required: false
    )
  end
end
