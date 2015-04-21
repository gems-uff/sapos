# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class StatesController < ApplicationController
  authorize_resource

  active_scaffold :state do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :code, :country]
    config.create.label = :create_state_label
    config.columns[:country].form_ui = :select
    config.columns[:country].clear_link
    config.create.columns = [:country, :name, :code]
    config.update.label = :update_state_label
    config.update.columns = [:country, :name, :code]
  end

  def cities
    cities = []
    unless params[:id] == 'cities'
      state = State.find_by_id(params[:id])
      cities = state.cities.collect {|c| [c.name, c.id]} unless state.nil?
    end
    respond_to do |format|
      format.json { render :json =>  cities}
    end
  end

end