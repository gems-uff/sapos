# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Helper for Dismissals
module DismissalsHelper
  def date_form_column(record, options)
    scholarship_month_year_widget record, options, :date, required: false
  end
end
