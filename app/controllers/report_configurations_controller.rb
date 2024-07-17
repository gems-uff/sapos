# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ReportConfigurationsController < ApplicationController
  authorize_resource
  skip_before_action :verify_authenticity_token, only: [:preview]

  include ApplicationHelper
  active_scaffold :report_configuration do |config|
    config.create.label = :create_report_configuration_label
    columns = [
      :name, :image, :scale, :x, :y, :order, :text, :signature_type,
      :preview, :use_at_report, :use_at_transcript,
      :use_at_grades_report, :use_at_schedule,
    ]
    config.create.columns = columns
    config.update.columns = columns
    columns.delete(:preview)
    config.columns = columns
    config.list.columns = [
      :name, :order, :text, :signature_type,
      :use_at_report, :use_at_transcript, :use_at_grades_report,
      :use_at_schedule,
    ]
    config.columns[:signature_type].form_ui = :select
    config.columns[:signature_type].options = { options: ReportConfiguration.signature_types.keys.map(&:to_sym) }
    config.list.sorting = { name: "ASC" }
    config.actions << :duplicate
    config.duplicate.link.label = "
      <i title='#{I18n.t("active_scaffold.duplicate")}' class='fa fa-copy'></i>
    ".html_safe
    config.actions.exclude :deleted_records
  end

  def preview
    id = params[:record_id].to_i
    if id != -1
      record = ReportConfiguration.find(id)
    else
      record = ReportConfiguration.new
    end
    record.assign_attributes(record_params.except(:image_cache, :remove_image))
    # up = ImageUploader.new record, :image
    # up.store(File.open(params[:record][:image]))
    @pdf_config = record.tap { |r| r.preview = true }
    respond_to do |format|
      format.pdf do
        title = I18n.t("pdf_content.report_configurations.preview")
        send_data render_to_string,
          filename: "#{title}.pdf",
          type: "application/pdf"
      end
    end
  end

  def logo
    record = ReportConfiguration.find params[:id]
    send_data(record.image.read, filename: record.image_identifier)
  end

  private
    def record_params
      params.required(:record).permit(
        :name, :use_at_report, :use_at_transcript, :use_at_grades_report,
        :use_at_schedule, :text, :image, :order, :scale,
        :x, :y, :signature_type
      )
    end
end
