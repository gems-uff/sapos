class StudentApplicationsController < ApplicationController
  authorize_resource

  active_scaffold :student_application do |config|
    config.list.sorting = {:application_process => 'ASC'}
    config.list.columns = [:application_process, :student]
    #config.create.label = :create_city_label
    #config.columns[:state].form_ui = :select
    #config.columns[:state].clear_link
    #config.create.columns = [:state, :name]
    #config.update.label = :update_city_label
    #config.update.columns = [:state, :name]

    config.actions.exclude :deleted_records
  end
end