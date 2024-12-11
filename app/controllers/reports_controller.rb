# frozen_string_literal: true

class ReportsController < ApplicationController
  before_action :set_report, only: [:download, :download_by_identifier]
  before_action :check_downloadable, only: [:download, :download_by_identifier]
  authorize_resource

  skip_authorization_check only: :download_by_identifier
  skip_authorize_resource only: :download_by_identifier
  skip_before_action :authenticate_user!, only: :download_by_identifier

  active_scaffold :report do |config|
    config.list.columns = [:user, :file_name, :identifier, :created_at, :expires_at]
    config.show.columns = [:user, :file_name, :identifier, :created_at, :expires_at]
    config.update.columns = [:expires_at]
    config.columns[:user].clear_link
    config.actions.exclude :create, :delete
    config.action_links.add "download",
                            label: "
        <i title='#{I18n.t("active_scaffold.download_link")}'
           class='fa fa-download'></i>
      ".html_safe,
                            page: true,
                            type: :member,
                            parameters: { format: :pdf },
                            method: :get,
                            html_options: { target: "_blank" },
                            ignore_method: :cant_download?
  end

  def download
    redirect_to download_path(medium_hash: @report.carrierwave_file.medium_hash)
  end

  def download_by_identifier
    send_data(@report.carrierwave_file.read, filename: @report.carrierwave_file.original_filename, disposition: :inline)
  end

  private
    def set_report
      @report = params[:id] ? Report.find(params[:id]) : Report.find_by_identifier(params[:identifier])
      raise ActionController::RoutingError.new("Este documento não foi encontrado.") if @report.nil?
    end

    def check_downloadable
      raise ActionController::RoutingError.new("Este documento expirou.") if cant_download?(@report)
    end

    def cant_download?(record)
      record.carrierwave_file.blank?
    end
end
