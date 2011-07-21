class EnrollmentStatusesController < ApplicationController
  active_scaffold :enrollment_status do |config|
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_enrollment_status_label
  end
end 