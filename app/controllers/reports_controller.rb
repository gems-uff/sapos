# frozen_string_literal: true

class ReportsController < ApplicationController
  include ReportsHelper

  before_action :set_report, only: [:download, :download_by_identifier, :invalidate]
  before_action :check_downloadable, only: [:download, :download_by_identifier]
  authorize_resource

  skip_authorization_check only: :download_by_identifier
  skip_authorize_resource only: :download_by_identifier
  skip_before_action :authenticate_user!, only: :download_by_identifier

  active_scaffold :report do |config|
    config.list.columns = [:user, :file_name, :identifier, :created_at, :expires_at_or_invalid]
    config.show.columns = [:user, :file_name, :identifier, :created_at, :expires_at, :invalidated_by, :invalidated_at]
    config.update.columns = [:expires_at]
    config.columns = config.list.columns
    config.list.sorting = { created_at: :desc }
    config.columns[:user].clear_link
    config.columns[:expires_at_or_invalid].label = I18n.t("activerecord.attributes.report.expires_at")
    config.create.columns = [:file_name, :document_title, :document_body, :expiration_in_months]
    config.columns.add :document_body, :expiration_in_months
    config.columns[:document_body].required = true
    config.columns[:expiration_in_months].label = I18n.t("activerecord.attributes.report_configuration.expiration_in_months")
    config.columns[:expiration_in_months].description = I18n.t("active_scaffold.expiration_in_months_description")
    config.columns[:expires_at].description = I18n.t("active_scaffold.expires_at_description")
    config.create.label = :create_report_label
    config.actions.exclude :delete
    config.action_links.add "download",
                            label: "
        <i title='#{I18n.t("active_scaffold.download_link")}'
           class='fa fa-download'></i>
      ".html_safe, page: true,
                   type: :member,
                   parameters: { format: :pdf },
                   method: :get,
                   html_options: { target: "_blank" },
                   ignore_method: :cant_download?

    config.action_links.add "invalidate",
                            label: "
        <i title='#{I18n.t("active_scaffold.invalidate_link")}'
            class='fa fa-times'></i>
      ".html_safe, page: true,
                   type: :member,
                   method: :put,
                   confirm: "Tem certeza que deseja invalidar este documento?",
                   ignore_method: :cant_download?
  end

  def before_create_save(record)
    record.user = current_user
    record.expires_at = Date.today + record.expiration_in_months.to_i.months if record.expiration_in_months.present?
    document_data = { body: params[:record][:document_body], title: params[:record][:document_title], expiration_in_months: params[:record][:expiration_in_months] }
    extension = File.extname(record.file_name)[1..-1]
    record.file_name = record.file_name + ".pdf" unless extension == "pdf"
    create_external_report_pdf(record, document_data)
  end

  def download
    redirect_to download_path(medium_hash: @report.carrierwave_file.medium_hash)
  end

  def download_by_identifier
    send_data(@report.carrierwave_file.read, filename: @report.carrierwave_file.original_filename, disposition: :inline)
  end

  def invalidate
    @report.invalidate!(user: current_user)

    redirect_to reports_path, notice: "Documento invalidado com sucesso."
  end

  private
    def set_report
      @report = params[:id] ? Report.find(params[:id]) : Report.find_by_identifier(params[:identifier])
      raise ActionController::RoutingError.new("Este documento não foi encontrado.") if @report.nil?
    end

    def check_downloadable
      render("reports/expired_or_invalid_report") if cant_download?(@report)
    end

    def cant_download?(record)
      record.carrierwave_file.blank?
    end
end
