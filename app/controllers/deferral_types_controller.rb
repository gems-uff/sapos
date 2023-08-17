# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class DeferralTypesController < ApplicationController
  authorize_resource

  active_scaffold :deferral_type do |config|
    config.list.sorting = { name: "ASC" }
    columns = [
      :name, :description, :duration_semesters,
      :duration_months, :duration_days, :phase
    ]
    config.list.columns = columns
    config.create.label = :create_deferral_type_label
    config.columns[:phase].clear_link
    config.columns[:phase].form_ui = :select
    config.create.columns = columns
    config.update.columns = columns
    config.show.columns = columns

    config.actions.exclude :deleted_records
  end
end
