# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CourseTypesController < ApplicationController
  authorize_resource

  active_scaffold :course_type do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :has_score, :schedulable, :show_class_name]
    config.create.label = :create_course_type_label
    config.update.label = :update_course_type_label

    config.columns =
        [:name, :has_score, :schedulable, :show_class_name]
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true

end 