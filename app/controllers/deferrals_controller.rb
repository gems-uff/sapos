# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class DeferralsController < ApplicationController
  authorize_resource

  active_scaffold :deferral do |config|
    config.list.sorting = { enrollment: "ASC" }

    config.columns[:enrollment].search_sql = "enrollments.enrollment_number"
    config.columns[:enrollment].form_ui = :record_select
    config.columns[:enrollment].send_form_on_update_column = true
    config.columns[:enrollment].update_columns = [:deferral_type]
    config.columns[:deferral_type].form_ui = :select
    config.columns[:approval_date].options = { format: :monthyear }

    config.create.columns = [:enrollment, :approval_date, :obs, :deferral_type]
    config.update.columns = [:enrollment, :approval_date, :obs, :deferral_type]
    config.show.columns = [:enrollment, :approval_date, :obs, :deferral_type]
    config.list.columns = [
      :enrollment, :approval_date, :deferral_type, :valid_until
    ]
    config.search.columns = [:enrollment]

    config.create.label = :create_deferral_label

    config.actions.exclude :deleted_records
  end
end
