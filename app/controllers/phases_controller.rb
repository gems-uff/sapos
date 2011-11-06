class PhasesController < ApplicationController
  active_scaffold :phase do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :description, :deadline]
    config.create.label = :create_phase_label
    config.columns[:enrollments].form_ui = :record_select
    config.columns[:level].form_ui = :select
    config.create.columns = [:name, :level, :description, :deadline, :accomplishments]
    config.update.columns = [:name, :level, :description, :deadline, :accomplishments]
    config.show.columns = [:name, :level, :description, :deadline, :enrollments]
  end
#  record_select :per_page => 10, :search_on => [:name], :order_by => 'name', :full_text_search => true
end 