class ApplicationProcessesController < ApplicationController
  authorize_resource

  active_scaffold :application_process do |config|
    config.columns.add :student_applications_count

    config.list.sorting = {:end_date => 'ASC'}
    config.list.columns = [:name, :year, :semester,:start_date, :end_date, :student_applications_count]

    config.columns[:student_applications].includes = [:students, :student_applications]

    config.columns = [
        :name,
        :start_date,
        :end_date,
        :year,
        :semester,
        :min_letters,
        :max_letters,
        :form_template,
        :letter_template,
        :student_applications_count,
        :student_applications
    ]
    config.create.label = :create_application_process_label
    config.columns[:form_template].form_ui = :select
    config.columns[:form_template].clear_link
    config.columns[:letter_template].form_ui = :select
    config.columns[:letter_template].clear_link
    config.create.columns = [:name, :year, :semester, :start_date, :end_date, :form_template, :letter_template, :min_letters, :max_letters]
    config.update.label = :update_application_process_label
    config.update.columns = [:name, :year, :semester, :start_date, :end_date, :min_letters, :max_letters]

    config.actions.exclude :deleted_records
  end

end