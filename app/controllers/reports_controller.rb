# frozen_string_literal: true

class ReportsController < ApplicationController
  authorize_resource

  active_scaffold :report do |config|
    config.list.columns = [:user, :created_at, :expires_at]
    config.show.columns = [:user, :created_at, :expires_at]
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
    report = Report.find(params[:id])
    redirect_to download_path(medium_hash: report.carrierwave_file.medium_hash)
  end

  private
    def cant_download?(record)
      record.carrierwave_file.blank?
    end
end
