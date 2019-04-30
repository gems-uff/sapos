# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class FormImagesController < ApplicationController
  authorize_resource
  include ApplicationHelper
  active_scaffold :form_image do |config|
    config.list.sorting = {:name => 'ASC'}   
    config.list.columns = [
        :name,  
        :text, 
    ]

    columns = [
        :name, 
        :image, 
        :text
    ]

    #config.columns[:form].search_ui = :record_select
    #config.columns[:form].form_ui = :record_select
    config.create.label = :create_form_image_label
    config.update.label = :update_form_image_label
    config.create.columns = columns
    config.update.columns = columns
    config.columns = columns

    config.actions.exclude :deleted_records
  end
  record_select :per_page => 10

  def logo
    record = FormImage.find params[:id]
    send_data(record.image.read, filename: record.image_identifier)
  end

  private
  def record_params
    params.required(:record).permit(:name, :text, :image)
  end
end
