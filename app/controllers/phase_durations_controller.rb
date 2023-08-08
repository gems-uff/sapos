# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class PhaseDurationsController < ApplicationController
  authorize_resource

  active_scaffold :phase_duration do |config|
    config.actions.exclude :deleted_records
  end
end
