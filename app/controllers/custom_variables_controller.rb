# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CustomVariablesController < ApplicationController
  authorize_resource

  active_scaffold :custom_variable do |config|
    config.list.sorting = {:name => 'ASC'}
    config.columns = [:name, :variable, :value]
    config.create.label = :create_custom_variable_label
    config.update.label = :update_custom_variable_label
  end
end
