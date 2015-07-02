# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CountriesController < ApplicationController
  authorize_resource

  active_scaffold :country do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name]
    config.create.label = :create_country_label
    config.create.columns = [:name, :nationality]
    config.update.label = :update_country_label
    config.update.columns = [:name, :nationality]
  end

  def states
    states = []
    unless params[:id] == 'states'
      country = Country.find_by_id(params[:id])
      states = country.state.collect {|s| [s.name, s.id]} unless country.nil?
    end
    respond_to do |format|
      format.json { render :json =>  states}
    end
  end

end 