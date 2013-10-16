# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class MajorsController < ApplicationController
  authorize_resource

  helper :student_majors

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

    config.columns[:student_majors].includes = [:students, :student_majors]

    config.list.columns = [:name, :level, :institution, :students]
    config.create.columns = [:name, :level, :institution, :student_majors]
    config.update.columns = [:name, :level, :institution, :student_majors]
    
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true
end 