# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AssertionsController < ApplicationController
  include SharedPdfConcern

  authorize_resource
  before_action :permit_query_params

  def permit_query_params
    params[:query_params].permit! unless params[:query_params].nil?
  end

  active_scaffold :assertion do |config|
    config.action_links.add "simulate",
                            label: "<i title='#{I18n.t("active_scaffold.assertion.simulate")}' class='fa fa-table'></i>".html_safe,
                            page: true,
                            inline: true,
                            position: :after,
                            type: :member

    form_columns = [
      :name, :student_can_generate, :query, :template_type, :assertion_template, :expiration_in_months
    ]

    config.create.label = :create_assertion_label
    config.list.sorting = { name: "ASC" }
    config.list.columns = [:name, :query]
    config.columns = form_columns
    config.update.columns = form_columns
    config.show.columns = form_columns
    config.actions.exclude :deleted_records

    config.columns[:expiration_in_months].description = I18n.t("active_scaffold.expiration_in_months_description")
    
    config.columns[:template_type].form_ui = :select
    config.columns[:template_type].options = {
      options: Assertion::TEMPLATE_TYPES,
    }

    config.columns[:query].form_ui = :select
  end

  def simulate
    @assertion = Assertion.find(params[:id])
    @args = @assertion.query.map_params(get_query_params)
    result = @assertion.query_results(@args)
    @messages = result[:rows] || []
    @query_sql = result[:query]

    # Allow user to simulate with different arguments
    # Analyzes derivations and builds new temporary parameters for missing ones
    # Also set simulation_value based on arguments
    @query_params = @assertion.query.params

    @query_result = result
    render action: "simulate"
  end

  def override_signature_assertion_pdf
    assertion_pdf(params[:signature_type])
  end

  def assertion_pdf(signature_type = nil)
    @assertion = Assertion.find(params[:id])

    authorize! :generate_assertion, @assertion, get_query_params[:matricula_aluno]

    args = @assertion.query.map_params(get_query_params)
    @assertion.args = args

    respond_to do |format|
      format.pdf do
        title = I18n.t("pdf_content.assertion.assertion_pdf.filename")
        assertion = @assertion.name
        filename = "#{title} - #{assertion}.pdf"
        send_data render_assertion_pdf(@assertion, filename, signature_type),
                  filename: filename,
                  type: "application/pdf"
      end
    end
  rescue ActionView::Template::Error => e
    if e.cause.is_a?(Exceptions::EmptyQueryException)
      redirect_back(fallback_location: root_path, flash: { warning: I18n.t("activerecord.errors.models.assertion.empty_query", matricula: get_query_params[:matricula_aluno]) })
      return
    end

    raise e
  end

  private
    def get_query_params
      return params[:query_params].to_unsafe_h if params[:query_params].is_a?(
        ActionController::Parameters
      )
      params[:query_params] || {}
    end
end
