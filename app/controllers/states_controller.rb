# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class StatesController < ApplicationController
  active_scaffold :state do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :code, :country]
    config.create.label = :create_state_label
    config.columns[:country].form_ui = :select
    config.columns[:country].clear_link
    config.create.columns = [:country, :name, :code]
    config.update.label = :update_state_label
    config.update.columns = [:country, :name, :code]
  end

end