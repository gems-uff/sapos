# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class NotificationParamsController < ApplicationController
  authorize_resource

  active_scaffold :notification_param do |config|
    config.columns = [:query_param, :value]

    config.actions.exclude :deleted_records
  end
end
