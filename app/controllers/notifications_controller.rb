# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class NotificationsController < ApplicationController
  include SharedPdfConcern

  authorize_resource
  helper PdfHelper
  helper EnrollmentsPdfHelper

  active_scaffold :"notification" do |config|
    config.action_links.add(
      "simulate",
      label: "<i title='#{I18n.t("active_scaffold.notification.simulate")}'
                 class='fa fa-table'></i>".html_safe,
      page: true,
      inline: true,
      position: :after,
      type: :member
    )

    form_columns = [
      :title, :frequency, :notification_offset, :query_offset, :query,
      :individual, :has_grades_report_pdf_attachment, :template_type,
      :to_template, :subject_template, :body_template
    ]
    config.columns = form_columns
    config.update.columns = form_columns
    config.create.columns = [
      :title, :frequency, :notification_offset, :query_offset, :query,
      :individual, :has_grades_report_pdf_attachment,
      :to_template, :subject_template, :body_template
    ]
    config.show.columns = form_columns + [:next_execution]
    config.list.columns = [
      :title, :frequency, :notification_offset, :query_offset, :next_execution
    ]

    config.columns[:query].form_ui = :select
    config.columns[:frequency].form_ui = :select
    config.columns[:frequency].options = { options: Notification::FREQUENCIES }
    config.columns[:frequency].description = I18n.t(
      "active_scaffold.notification.frequency_description"
    )
    config.columns[:individual].description = I18n.t(
      "active_scaffold.notification.individual_description"
    )
    config.columns[:has_grades_report_pdf_attachment].description = I18n.t(
      "active_scaffold.notification.has_grades_report_pdf_attachment_description"
    )
    config.columns[:notification_offset].description = I18n.t(
      "active_scaffold.notification.notification_offset_description"
    )
    config.columns[:query_offset].description = I18n.t(
      "active_scaffold.notification.query_offset_description"
    )
    config.columns[:query].send_form_on_update_column = true
    config.columns[:query].update_columns = [:body_template, :query]
    config.columns[:template_type].form_ui = :select
    config.columns[:template_type].options = {
      options: Notification::TEMPLATE_TYPES,
    }
    # config.columns[:to_template].description = "Use {% emails Secretaria %} para todos emails de usuários da secretaria."


    config.create.label = :create_notification_label

    config.actions.exclude :deleted_records
  end

  def after_update_save(record)
    record.update_next_execution!
  end

  def execute_now
    process_action_link_action do |notification|
      result = notification.execute(override_params: get_query_params(notification))
      Notifier.send_emails(prepare_attachments(result))
      self.successful = true

      flash[:info] = I18n.t("active_scaffold.notification.execute_now_success")
    end
  end

  def simulate
    @notification = Notification.find(params[:id])
    # Execute notification with current parameters
    args = prepare_simulation_args
    result = @notification.execute(skip_update: true, override_params: args)
    @messages = result[:notifications]
    @query_sql = result[:query]

    # Allow user to simulate with different arguments
    # Analyzes derivations and builds new temporary parameters for missing ones
    # Also set simulation_value based on arguments
    @query_params = @notification.query.params
    existing_der = Set.new
    used_der = Set.new
    @query_params.each do |param|
      # Find derivations
      name = param.name
      existing_der << name if Notification::DERIVATION_DEFS.include? name
      derivation = Notification::DERIVED_PARAMS[name]
      used_der << derivation if derivation.present?
      # Set default value
      user_value = args[name.to_sym]
      param.simulation_value = user_value unless user_value.nil?
    end
    missing_derivations = used_der - existing_der
    missing_derivations.each do |param_name|
      param = @query_params.build(Notification::DERIVATION_DEFS[param_name])
      # Set default value
      user_value = args[param_name.to_sym]
      param.simulation_value = user_value unless user_value.nil?
    end

    render action: "simulate"
  end

  private
    # Data mal digitada na tela de simulação é erro de preenchimento, não
    # defeito: avisa e simula com a data padrão da notificação, em vez de
    # derrubar a página.
    def prepare_simulation_args
      query_params = get_query_params(@notification)
      @notification.prepare_params_and_derivations(query_params)
    rescue Date::Error
      flash.now[:alert] = I18n.t(
        "activerecord.errors.models.notification.invalid_query_date",
        date: query_params[:data_consulta]
      )
      @notification.prepare_params_and_derivations(
        query_params.except(:data_consulta)
      )
    end

    # Só as chaves que a consulta declara passam, mais data_consulta, a
    # derivação que o formulário de simulação envia e de onde as demais
    # (semestre e ano atual e anterior) são calculadas no modelo. Os valores
    # seguem para a consulta como parâmetros ligados, mas o permit! de antes
    # aceitava qualquer chave, e não há por que aceitar o que a consulta não pede.
    def get_query_params(notification)
      raw = params[:query_params]
      return {}.with_indifferent_access unless raw.is_a?(ActionController::Parameters)
      allowed = notification.query.params.map(&:name) + Notification::DERIVATION_DEFS.keys
      raw.permit(*allowed).to_h
    end
end
