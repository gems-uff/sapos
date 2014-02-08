# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CustomVariablesController < ApplicationController
  authorize_resource

  active_scaffold :custom_variable do |config|
    config.list.sorting = {:name => 'ASC'}
    config.columns[:variable].form_ui = :select
    config.columns[:variable].options = {:options => CustomVariable::VARIABLES}
    config.create.multipart = true
    config.update.multipart = true
    
    config.columns = [:name, :variable, :value]
    config.create.label = :create_custom_variable_label
    config.update.label = :update_custom_variable_label
  end

  def save_image(record)
    return if record.variable != "logo"
    uploaded_io = params[:record][:file_value]
    scale = params[:record][:value_scale] || 0.4
    x = params[:record][:value_x] || 13
    y = params[:record][:value_y] || 77
    record.value = "#{record.value_filename}|#{scale}|#{x}|#{y}"
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
end
