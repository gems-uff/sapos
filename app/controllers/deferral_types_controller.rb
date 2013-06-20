# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class DeferralTypesController < ApplicationController
  active_scaffold :deferral_type do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :description, :duration_semesters, :duration_months, :duration_days, :phase]
    config.create.label = :create_deferral_type_label
    config.columns[:phase].clear_link
    config.columns[:phase].form_ui = :select
    config.create.columns = [:name, :description, :duration_semesters, :duration_months, :duration_days, :phase]
    config.update.columns = [:name, :description, :duration_semesters, :duration_months, :duration_days, :phase]
    config.show.columns = [:name, :description, :duration_semesters, :duration_months, :duration_days, :phase]
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
