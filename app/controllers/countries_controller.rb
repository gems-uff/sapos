# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CountriesController < ApplicationController
  authorize_resource

  active_scaffold :country do |config|
    config.create.label = :create_country_label
    config.list.sorting = { name: "ASC" }
    config.columns = [:name, :nationality]

    config.actions.exclude :deleted_records
  end

  def states
    states = []
    unless params[:id] == "states"
      country = Country.find_by_id(params[:id])
      states = country.state.collect { |s| [s.name, s.id] } unless country.nil?
    end
    respond_to do |format|
      format.json { render json: states }
    end
  end
end
