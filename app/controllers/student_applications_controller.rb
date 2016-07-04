class StudentApplicationsController < ApplicationController

  active_scaffold :student_application do |config|
    config.list.sorting = [:application_process => 'ASC']
    config.list.columns = [:application_process, :student]
    config.columns = [
        :student
    ]

    config.actions.exclude :delete, :update
    # config.actions.exclude :update
  end

  record_select :per_page => 10, :search_on => :application_process, :full_text_search => true

end