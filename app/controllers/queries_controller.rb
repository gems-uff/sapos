# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class QueriesController < ApplicationController
  authorize_resource

  active_scaffold :query do |config|
    config.create.label = :create_query_label
    config.action_links.add "execute",
      label: "<i title='#{I18n.t("active_scaffold.query.execute")}'
                 class='fa fa-table'></i>".html_safe,
      page: true,
      inline: true,
      position: :after,
      type: :member

    config.update.columns = [:name, :description, :params, :sql]
    config.list.columns = [:name, :description, :assertions, :notifications]
    config.columns[:description].form_ui = :textarea
    config.columns[:description].options = { cols: 124, rows: 3 }
    config.columns[:params].allow_add_existing = false
    config.columns[:params].clear_link
    config.create.columns = [:name, :description, :params, :sql]

    config.actions.exclude :deleted_records
  end


  def execute
    @query = Query.find(params[:id])
    @query_result = @query.execute(get_simulation_params)
    render action: "execute"
  end

  private
    def get_simulation_params
      return params[:query_params].to_unsafe_h if params[:query_params].is_a?(
        ActionController::Parameters
      )
      params[:query_params] || {}
    end
end
