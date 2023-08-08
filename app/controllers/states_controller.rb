# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class StatesController < ApplicationController
  authorize_resource

  active_scaffold :state do |config|
    config.create.label = :create_state_label
    config.list.sorting = { name: "ASC" }
    config.list.columns = [:name, :code, :country]
    config.columns = [:country, :name, :code]
    config.columns[:country].form_ui = :select
    config.columns[:country].clear_link

    config.actions.exclude :deleted_records
  end

  def cities
    cities = []
    unless params[:id] == "cities"
      state = State.find_by_id(params[:id])
      cities = state.cities.collect { |c| [c.name, c.id] } unless state.nil?
    end
    respond_to do |format|
      format.json { render json: cities }
    end
  end
end
