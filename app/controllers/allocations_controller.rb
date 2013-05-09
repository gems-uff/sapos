class AllocationsController < ApplicationController
  active_scaffold :allocation do |config|
    config.list.sorting = {:course_class => 'ASC'}
    config.list.columns = [:course_class, :day, :room, :start_time, :end_time]
    config.create.label = :create_allocation_label
    config.update.label = :update_allocation_label

    config.columns[:course_class].clear_link
    config.columns[:course_class].form_ui = :record_select
    config.columns[:day].form_ui = :select
    config.columns[:day].options = {:options => I18n.translate("date.day_names")}

    config.columns =
        [:course_class, :day, :room, :start_time, :end_time]

  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true
end