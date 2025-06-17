# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Helper for Dismissals
module DismissalsHelper
  def date_search_column(record, options)
    month_year_widget record, options, :date, required: false, multiparameter: false,
    date_options: { discard_month: true, prefix: options[:name] }
  end

  def enrollment_level_search_column(record, options)
    local_options = {
        include_blank: true
    }

    select_tag(
      record[:level],
      options_from_collection_for_select(Level.order("name"), "id", "name"),
      options.merge(local_options)
    )
  end

  def date_form_column(record, options)
    month_year_widget record, options, :date, required: false
  end
end
