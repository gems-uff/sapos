# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class NotificationParamsController < ApplicationController
  authorize_resource

  active_scaffold :notification_param do |config|
    config.columns = [:query_param, :value]

    # config.columns[:value_type].required = false
    # config.columns[:name].required = false
    # config.columns[:query_param].form_ui = :select
    # config.columns[:value_type].options = { options:  QueryParam::VALUE_TYPES, :include_blank => 'Escolha'}
    # config.columns[:value_type].update_columns = [:default_value]
  end
end
