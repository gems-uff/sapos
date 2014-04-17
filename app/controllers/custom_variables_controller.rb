# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CustomVariablesController < ApplicationController
  authorize_resource
  include ApplicationHelper
  active_scaffold :custom_variable do |config|
    config.list.sorting = {:name => 'ASC'}
    config.columns[:variable].form_ui = :select
    config.columns[:variable].options = {:options => CustomVariable::VARIABLES.keys}
    config.create.multipart = true
    config.update.multipart = true
    
    config.columns = [:name, :variable, :value]
    config.create.label = :create_custom_variable_label
    config.update.label = :update_custom_variable_label
  end

  def save_image(record, options={})
    return if CustomVariable::VARIABLES[record.variable] != :pdfimage
    puts params
    uploaded_io = params[:record][:file_value]

    scale = params[:record][:value_scale]
    x = params[:record][:value_x]
    y = params[:record][:value_y]
    text = params[:record][:value_text]
    filename = record.image.filename

    if not uploaded_io.nil?
      if options[:name].nil? or options[:name].empty?
        filename = uploaded_io.original_filename
      else
        extension = ".#{uploaded_io.original_filename.split('.')[-1]}"
        filename = "#{options[:name]}#{extension}"
      end

      File.open(HeaderVariable.file_path(filename), 'wb') do |file|
        file.write(uploaded_io.read)
      end
    end

    HeaderVariable.new(
      :filename => filename,
      :scale => scale,
      :x => x,
      :y => y,
      :text => text
    )
  end

  def before_update_save(record)
    record.value = save_image(record).to_s
  end

  def before_create_save(record)
    record.value = save_image(record).to_s
  end

  def preview
    if params[:record]
      record = CustomVariable.find_by_variable(params[:record][:variable])
      @pdf_header = save_image(record, name: "temp")
    else
      @pdf_header = CustomVariable.pdf_header
    end
    respond_to do |format|
      format.pdf do
        send_data render_to_string, :filename => I18n.t("pdf_content.custom_variables.pdf_header.preview"), :type => 'application/pdf'
      end
    end
  end
end
