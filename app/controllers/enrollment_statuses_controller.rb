class EnrollmentStatusesController < ApplicationController
  active_scaffold :enrollment_status do |config|
    config.list.sorting = {:name => 'ASC'}
    config.create.label = :create_enrollment_status_label
  end
  record_select :per_page => 10, :search_on => [:name], :order_by => 'name'
end 