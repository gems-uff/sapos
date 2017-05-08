class StudentApplicationsController < ApplicationController
  authorize_resource

  active_scaffold :student_application do |config|

    config.columns.add :application_form_template
    config.list.columns = [:student, :application_process, :student_cpf, :requested_letters, :filled_letters]

    #config.create.columns = columns
    #config.update.columns = columns
    columns = [:student, :application_process, :student_cpf, :requested_letters, :filled_letters, :form_fields, :letter_requests]

    config.show.columns = columns

    config.columns[:student].form_ui = :record_select
    config.columns[:application_process].form_ui = :record_select

    #config.nested.add_link(:letter_requests)

    config.actions.exclude :deleted_records, :delete, :update
  end

  record_select

end