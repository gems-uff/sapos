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

  def save_image(record)
    return if CustomVariable::VARIABLES[record.variable] != :pdfimage
    uploaded_io = params[:record][:file_value]
    scale = params[:record][:value_scale] || 0.4
    x = params[:record][:value_x] || 13
    y = params[:record][:value_y] || 77
    record.value = "#{record.image.filename}|#{scale}|#{x}|#{y}"
    return if uploaded_io.nil?
    record.value = "#{uploaded_io.original_filename}|#{scale}|#{x}|#{y}"
    File.open(Rails.root.join('app', 'assets', 'images', 'custom_variables', uploaded_io.original_filename), 'wb') do |file|
      file.write(uploaded_io.read)
    end
    
  end

  def before_update_save(record)
    save_image(record)
  end

  def before_create_save(record)
    save_image(record)
  end

  def preview
    puts "================="
    puts params
    puts "================="
    record = CustomVariable.find_by_variable(params[:record][:variable])
    uploaded_io = params[:record][:file_value]
    
    scale = params[:record][:value_scale] || 0.4
    x = params[:record][:value_x] || 13
    y = params[:record][:value_y] || 77
    filename = record.image.filename
    unless uploaded_io.nil?
        extension = ".#{uploaded_io.original_filename.split('.')[-1]}"
        filename = "temp#{extension}"
        File.open(Rails.root.join('app', 'assets', 'images', 'custom_variables', "temp#{extension}"), 'wb') do |file|
          file.write(uploaded_io.read)
        end
    end
    text = "#{filename}|#{scale}|#{x}|#{y}"
    @logo = ImageVariable.new(text)
    respond_to do |format|
      format.pdf do
        send_data render_to_string, :filename => I18n.t("pdf_content.custom_variables.logo.preview"), :type => 'application/pdf'
      end
    end
  end
end
