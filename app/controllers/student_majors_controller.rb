class StudentMajorsController < ApplicationController
  authorize_resource

  active_scaffold :student_major do |config|
    columns = [:student, :major]

    config.list.columns = columns
    config.create.columns = columns
    config.update.columns = columns
    config.show.columns = columns

    config.columns[:student].form_ui = :record_select
    config.columns[:major].form_ui = :record_select

  end

  record_select
end
