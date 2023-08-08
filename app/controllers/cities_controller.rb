# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CitiesController < ApplicationController
  authorize_resource

  active_scaffold :city do |config|
    config.create.label = :create_city_label
    config.list.sorting = { name: "ASC" }
    config.list.columns = [:name, :state]
    config.columns = [:state, :name]
    config.columns[:state].form_ui = :select
    config.columns[:state].clear_link

    config.actions.exclude :deleted_records
  end
end
