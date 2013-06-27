# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class MajorsController < ApplicationController
  authorize_resource

  active_scaffold :major do |config|
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_major_label
    #este abaixo não está funcionando...
    config.update.label = :update_major_label

    config.columns[:institution].clear_link
    config.columns[:level].clear_link
    config.columns[:students].clear_link
    config.columns[:level].form_ui = :select
    config.columns[:institution].form_ui = :record_select
    config.columns[:students].form_ui = :record_select
    config.create.columns = [:name, :level, :institution, :students]
    config.update.columns = [:name, :level, :institution, :students]
    
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true
end 