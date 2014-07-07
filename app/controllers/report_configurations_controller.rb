# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ReportConfigurationsController < ApplicationController
  authorize_resource
  include ApplicationHelper
  active_scaffold :report_configuration do |config|
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_report_configuration_label
    config.update.label = :update_report_configuration_label    
    config.actions << :duplicate
    config.duplicate.link.label = "<i title='#{I18n.t('active_scaffold.duplicate')}' class='fa fa-copy'></i>".html_safe
    config.list.columns = [
        :name, 
        :order, 
        :text, 
        :signature_footer, 
        :use_at_report, 
        :use_at_transcript,
        :use_at_grades_report,
        :use_at_schedule
    ]

    columns = [
        :name, 
        :image,
        :scale,
        :x,
        :y,
        :order, 
        :text, 
        :signature_footer, 
        :preview,
        :use_at_report, 
        :use_at_transcript,
        :use_at_grades_report,
        :use_at_schedule,
    ]

    config.create.columns = columns
    config.update.columns = columns
    columns.delete(:preview)
    config.columns = columns
    
  end

  def preview
    id = params[:record_id].to_i
    if id != -1
      record = ReportConfiguration.find(id)
    else
      record = ReportConfiguration.new
    end

    record.assign_attributes(params[:record].except(:image_cache, :remove_image))
    # up = ImageUploader.new record, :image
    # up.store(File.open(params[:record][:image]))
    @pdf_config = record
    respond_to do |format|
      format.pdf do
        send_data render_to_string, :filename => I18n.t("pdf_content.report_configurations.preview"), :type => 'application/pdf'
      end
    end
  end
end