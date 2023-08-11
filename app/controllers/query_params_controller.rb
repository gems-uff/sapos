# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class QueryParamsController < ApplicationController
  authorize_resource

  active_scaffold :query_param do |config|
    config.columns = [:value_type, :name, :default_value]
    config.columns[:value_type].required = false
    config.columns[:name].required = false
    config.columns[:value_type].form_ui = :select
    config.columns[:value_type].options = {
      options: QueryParam::VALUE_TYPES,
      include_blank: "Escolha"
    }

    config.actions.exclude :deleted_records
  end
end
