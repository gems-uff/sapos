# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class InstitutionsController < ApplicationController
  active_scaffold :institution do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :code]
    config.create.label = :create_institution_label
    config.columns = [:name, :code, :majors]
    config.columns[:majors].associated_limit = nil
    config.columns[:majors].form_ui = :record_select

  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true

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