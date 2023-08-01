# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Helper for Deferrals
module DeferralsHelper
  def approval_date_form_column(record, options)
    scholarship_month_year_widget record, options, :approval_date
  end

  # TODO: remove current deferraltype if enrollment was changed
  def options_for_association_conditions(association, record)
    if association.name == :deferral_type
      DeferralType.find_all_for_enrollment(record.enrollment)
    else
      super
    end
  end
end
