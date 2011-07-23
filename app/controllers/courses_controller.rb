class CoursesController < ApplicationController
  active_scaffold :course do |config|    
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_course_label
    #este abaixo não está funcionando...
    config.update.label = :update_course_label
  end
  record_select :per_page => 3, :search_on => [:name], :order_by => 'name'
end 