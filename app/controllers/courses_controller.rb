class CoursesController < ApplicationController
  active_scaffold :course do |config|    
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_course_label
    #este abaixo não está funcionando...
    config.update.label = :update_course_label
    
    config.columns[:level].form_ui = :select
    config.create.columns = [:name, :level, :institution]
    config.update.columns = [:name, :level, :institution]
    
  end
  record_select :per_page => 5, :search_on => [:name], :order_by => 'name'
end 