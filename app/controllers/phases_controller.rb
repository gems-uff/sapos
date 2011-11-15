class PhasesController < ApplicationController
  active_scaffold :phase do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :description]
    config.create.label = :create_phase_label
    config.columns[:enrollments].form_ui = :record_select
#    config.columns[:levels].form_ui = :select
    config.create.columns = [:name, :description, :phase_durations]
    config.update.columns = [:name, :description, :phase_durations]
    config.show.columns = [:name, :description, :enrollments]
  end
#  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true
end 