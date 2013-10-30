# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CoursesController < ApplicationController
  authorize_resource

  active_scaffold :course do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :code, :research_area, :credits, :course_type]
    config.create.label = :create_course_label
    config.update.label = :update_course_label

    config.columns[:research_area].form_ui = :record_select
    config.columns[:course_type].form_ui = :select

    config.columns =
        [:name, :code, :credits, :research_area, :content, :course_type]
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true

end 