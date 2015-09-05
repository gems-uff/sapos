# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CitiesController < ApplicationController
  authorize_resource

  active_scaffold :city do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :state]
    config.create.label = :create_city_label
    config.columns[:state].form_ui = :select
    config.columns[:state].clear_link
    config.create.columns = [:state, :name]
    config.update.label = :update_city_label
    config.update.columns = [:state, :name]

    config.actions.exclude :deleted_records
  end

end 