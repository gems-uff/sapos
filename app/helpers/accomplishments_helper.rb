# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Helper for Accomplishments
module AccomplishmentsHelper
  def conclusion_date_form_column(record, options)
    month_year_widget record, options, :conclusion_date
  end

  # TODO: remove current accomplishments and current deferral_type if level was changed
  def options_for_association_conditions(association, record)
    if association.name == :phase
      Phase.find_all_for_enrollment(record.enrollment)
    else
      super
    end
  end
end
