# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AssertionsController < ApplicationController
  include SharedPdfConcern

  authorize_resource

  active_scaffold :assertion do |config|
    config.action_links.add "execute",
      label: "<i title='Execute' class='fa fa-table'></i>".html_safe,
      page: true,
      inline: true,
      position: :after,
      type: :member
    config.action_links.add "assertion_pdf",
      label: "<i title='#{I18n.t("activerecord.pdf_content.assertion.assertion_pdf")}' class='fa fa-file-text-o'></i>".html_safe,
      page: true,
      type: :member,
      parameters: { format: :pdf }

    form_columns = [
      :name, :query, :assertion_template, :assertion_box_width, :assertion_box_height
    ]

    config.create.label = :create_assertion_label
    config.list.sorting = { name: "ASC" }
    config.list.columns = [:name, :query]
    config.columns = form_columns
    config.update.columns = form_columns
    config.show.columns = form_columns
    config.actions.exclude :deleted_records

    config.columns[:query].form_ui = :select
  end

  def execute
    @assertion = Assertion.find(params[:id])
    args = @assertion.query.map_params(get_query_params)
    result = @assertion.query.execute(args)
    @query_sql = result[:query]

    # Allow user to simulate with different arguments
    # Analyzes derivations and builds new temporary parameters for missing ones
    # Also set simulation_value based on arguments
    @query_params = @assertion.query.params
    existing_der = Set.new
    used_der = Set.new
    @query_params.each do |param|
      # Find derivations
      name = param.name
      existing_der << name if Assertion::DERIVATION_DEFS.include? name
      derivation = Assertion::DERIVED_PARAMS[name]
      used_der << derivation if derivation.present?
      # Set default value
      user_value = args[name.to_sym]
      param.simulation_value = user_value unless user_value.nil?
    end

    @query_result = @assertion.query.execute
    render action: "execute"
  end

  def assertion_pdf
    @assertion = Assertion.find(params[:id])
    args = @assertion.query.map_params(get_query_params)
    result = @assertion.query.execute(args)

    respond_to do |format|
      format.pdf do
        title = "Query Results"
        send_data render_assertion_pdf(result),
          filename: "#{title} - #{@assertion.name}.pdf",
          type: "application/pdf"
      end
    end
  end

  private
  def get_query_params
    return params[:query_params].to_unsafe_h if params[:query_params].is_a?(ActionController::Parameters)
    params[:query_params] || {}
  end

end
