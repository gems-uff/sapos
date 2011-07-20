class CoursesController < ApplicationController
  active_scaffold :course do |config|    
    config.list.sorting = {:name => 'ASC'}    
  end
end 