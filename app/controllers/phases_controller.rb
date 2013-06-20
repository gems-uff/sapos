# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class PhasesController < ApplicationController
  active_scaffold :phase do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :description]
    config.create.label = :create_phase_label
    config.columns[:enrollments].form_ui = :record_select
#    config.columns[:levels].form_ui = :select
    config.create.columns = [:name, :description, :phase_durations]
    config.update.columns = [:name, :description, :phase_durations]
    config.show.columns = [:name, :description, :phase_durations, :enrollments]
  end
#  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true

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