class ScholarshipDurationsController < ApplicationController
  active_scaffold :scholarship_duration do |config|
    config.list.sorting = {:scholarship => 'ASC'}
    config.list.columns = [:scholarship, :start_date, :end_date, :enrollment]
    config.create.label = :create_scholarship_duration_label
    config.columns[:scholarship].form_ui = :select
    config.create.columns = [:scholarship, :start_date, :end_date, :obs, :enrollment]
    config.update.columns = [:scholarship, :start_date, :end_date, :obs, :enrollment]
  end
end 