# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CoursesController < ApplicationController
  authorize_resource
  helper :course_research_areas

  active_scaffold :course do |config|


    config.list.sorting = {:name => 'ASC'}

    config.columns.add :workload_text

    config.columns[:course_research_areas].includes = {:research_areas => :course_research_areas}

    config.list.columns = [:name, :code, :course_research_areas, :credits, :workload_text, :course_type, :available]
    config.create.label = :create_course_label
    config.update.label = :update_course_label

    config.actions.swap :search, :field_search

    config.field_search.columns = [
      :name, 
      :course_type, 
      :course_research_areas, 
      :available
    ]

    config.columns[:name].search_ui = :text

    config.columns[:course_type].form_ui = :select

    config.columns =
        [:name, :code, :credits, :workload, :course_research_areas, :content, :course_type, :available]
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true

  def record_select_conditions_from_controller
    if params[:available]
      [Course.arel_table[:available].eq(true).to_sql]
    else
      super
    end
  end

end 