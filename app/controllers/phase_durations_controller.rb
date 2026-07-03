# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class PhaseDurationsController < ApplicationController
  authorize_resource

  active_scaffold :phase_duration do |config|
    columns = [
      :deadline_semesters, :deadline_months, :deadline_days, :level
    ]
    config.columns = columns
    config.create.columns = columns
    config.update.columns = columns

    config.columns[:level].form_ui = :select
    config.columns[:level].clear_link

    config.actions.exclude :deleted_records
  end
end
