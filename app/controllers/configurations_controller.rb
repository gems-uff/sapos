# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ConfigurationsController < ApplicationController
  authorize_resource

  active_scaffold :configuration do |config|
    config.list.sorting = {:name => 'ASC'}
    config.columns = [:name, :variable, :value]
    config.create.label = :create_configuration_label
    config.update.label = :update_configuration_label
  end
end
