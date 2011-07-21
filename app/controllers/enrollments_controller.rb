class EnrollmentsController < ApplicationController
  active_scaffold :enrollment do |config|
    config.list.columns = [:student, :enrollment_number, :level, :enrollment_status, :admission_date, :dismissal, :obs]
    #config.list.columns = [:student, :enrollment_number, :level, :enrollment_status, :admission_date, :dismissal, :obs]
    config.list.sorting = {:enrollment_number => 'ASC'}
    config.create.label = :create_enrollment_label
    #config.columns[:student].inplace_edit = true
  end
end 