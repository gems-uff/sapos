class ClassEnrollmentsController < ApplicationController
  active_scaffold :class_enrollment do |config|
    config.list.sorting = {:enrollment => 'ASC'}
    config.list.columns = [:enrollment, :situation, :grade, :attendance]
    config.create.label = :create_class_enrollment_label
    config.update.label = :update_class_enrollment_label

    config.columns[:enrollment].clear_link
    config.columns[:course_class].clear_link
    config.columns[:enrollment].form_ui = :record_select
    config.columns[:course_class].form_ui = :record_select
    config.columns[:situation].form_ui = :select
    config.columns[:situation].options = {:options => ClassEnrollment::SITUATIONS}

    config.columns =
        [:enrollment, :course_class, :situation, :grade, :attendance, :obs]

  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true
end 