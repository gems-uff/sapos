class ApplicationProcessesController < ApplicationController
  authorize_resource

  active_scaffold :application_process do |config|
    config.list.sorting = {:end_date => 'ASC'}
    config.list.columns = [:name, :year, :semester, :end_date]
    #config.create.label = :create_city_label
    #config.columns[:state].form_ui = :select
    #config.columns[:state].clear_link
    #config.create.columns = [:state, :name]
    #config.update.label = :update_city_label
    #config.update.columns = [:state, :name]

    config.actions.exclude :deleted_records
  end

end