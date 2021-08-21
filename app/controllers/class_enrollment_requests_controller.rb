class ClassEnrollmentRequestsController < ApplicationController
  authorize_resource
  
  active_scaffold :"class_enrollment_request" do |config|
    config.list.sorting = {:enrollment_request => 'ASC'}
    config.columns = [:enrollment_request, :course_class, :status, :class_enrollment]
    config.create.label = :create_class_enrollment_request_label
    config.update.label = :update_class_enrollment_request_label

    config.columns[:enrollment_request].form_ui = :record_select
    config.columns[:course_class].form_ui = :record_select
    config.columns[:status].form_ui = :select
    config.columns[:status].options = {:options => ClassEnrollmentRequest::STATUSES, default: ClassEnrollmentRequest::REQUESTED, :include_blank => I18n.t("active_scaffold._select_")}

    config.actions.exclude :deleted_records
  end
end
