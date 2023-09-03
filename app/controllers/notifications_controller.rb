# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class NotificationsController < ApplicationController
  include SharedPdfConcern

  authorize_resource
  skip_authorization_check only: [:notify]
  skip_before_action :authenticate_user!, only: :notify
  before_action :permit_query_params
  helper PdfHelper
  helper EnrollmentsPdfHelper

  def permit_query_params
    params[:query_params].permit! unless params[:query_params].nil?
  end

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
      :individual, :has_grades_report_pdf_attachment,
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
    config.columns[:query].update_columns = [:query]


    config.create.label = :create_notification_label

    config.actions.exclude :deleted_records
  end

  def after_update_save(record)
    record.update_next_execution!
  end

  def execute_now
    process_action_link_action do |notification|
      result = notification.execute(override_params: get_query_params)
      Notifier.send_emails(prepare_attachments(result))
      self.successful = true

      flash[:info] = I18n.t("active_scaffold.notification.execute_now_success")
    end
  end

  def simulate
    @notification = Notification.find(params[:id])
    # Execute notification with current parameters
    args = @notification.prepare_params_and_derivations(get_query_params)
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

  def notify
    Notifier.logger.info "Sending Registered Notifications"

    Notifier.logger.info "[Notifications] #{Time.now.to_fs} - Notifications from DB"
    notifications = []
    notifications_attachments = {}

    # Get the next execution time arel table
    next_execution = Notification.arel_table[:next_execution]

    # Find notifications that should run
    Notification.where.not(frequency: Notification::MANUAL)
      .where(next_execution.lt(Time.now)).each do |notification|
        result = prepare_attachments(notification.execute)
        notifications.concat(result[:notifications])
        notifications_attachments.merge!(result[:notifications_attachments])
      end

    Notifier.send_emails({
      notifications: notifications,
      notifications_attachments: notifications_attachments
    })

    render inline: "Ok", content_type: "text/html"
  end

  private
    def get_query_params
      return params[:query_params].to_unsafe_h if params[:query_params].is_a?(
        ActionController::Parameters
      )
      params[:query_params] || {}
    end

    def prepare_attachments(notification_result)
      notification_result[:notifications].each do |message|
        attachments = notification_result[:notifications_attachments][message]
        next if attachments.blank?
        if attachments[:grades_report_pdf]
          enrollment = Enrollment.find(message[:enrollments_id])
          attachments[:grades_report_pdf][:file_contents] =
            render_enrollments_grades_report_pdf(enrollment)
        end
      end
      notification_result
    end
end
