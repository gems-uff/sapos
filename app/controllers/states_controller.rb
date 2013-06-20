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

  def update_authorized?(record=nil)
    can? :update, record
  end

  def create_authorized?(record=nil)
    can? :create, record
  end

  def show_authorized?(record=nil)
    can? :read, record
  end

  def delete_authorized?(record=nil)
    can? :delete, record
  end
end