class CourseClassesController < ApplicationController
  active_scaffold :course_class do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :course, :professor, :year, :semester]
    config.create.label = :create_course_class_label
    config.update.label = :update_course_class_label

    config.columns[:course].clear_link
    config.columns[:professor].clear_link
    config.columns[:course].form_ui = :record_select
    config.columns[:professor].form_ui = :record_select
    config.columns[:year].form_ui = :select
    config.columns[:semester].form_ui = :select
    config.columns[:semester].options = {:options => ['1','2']}
    config.columns[:year].options = {:options => ((Date.today.year-5)..Date.today.year).map {|y| y}.reverse}

    config.create.columns =
        [:name, :course, :professor, :year, :semester]

    config.update.columns =
        [:name, :course, :professor, :class_enrollments, :allocations, :year, :semester]
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true
end 