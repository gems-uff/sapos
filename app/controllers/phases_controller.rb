# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class PhasesController < ApplicationController
  authorize_resource

  active_scaffold :phase do |config|
    config.list.sorting = { name: "ASC" }
    config.list.columns = [
      :name, :description, :is_language, :extend_on_hold
    ]
    config.create.label = :create_phase_label
    config.columns[:enrollments].form_ui = :record_select
    form_columns = [
      :name, :description, :is_language, :extend_on_hold,
      :active, :phase_durations
    ]
    config.create.columns = form_columns
    config.update.columns = form_columns
    config.show.columns = form_columns + [:enrollments]

    config.actions.exclude :deleted_records
  end
end
