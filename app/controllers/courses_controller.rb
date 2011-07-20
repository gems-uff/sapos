class CoursesController < ApplicationController
  active_scaffold :course do |config|    
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_course_label   
  end
end 