class ClassEnrollmentRequestsController < ApplicationController
  authorize_resource
  
  active_scaffold :"class_enrollment_request" do |config|
    config.list.sorting = {:enrollment_request => 'ASC'}
    config.columns = [:enrollment_request, :course_class, :status_professor, :status_coord]
    config.create.label = :create_class_enrollment_request_label
    config.update.label = :update_class_enrollment_request_label

    config.columns[:enrollment_request].form_ui = :record_select
    config.columns[:course_class].form_ui = :record_select
    config.columns[:status_professor].form_ui = :select
    config.columns[:status_professor].options = {:options => ClassEnrollmentRequest::STATUSES, default: ClassEnrollmentRequest::REGISTERED, :include_blank => I18n.t("active_scaffold._select_")}
    config.columns[:status_coord].form_ui = :select
    config.columns[:status_coord].options = {:options => ClassEnrollmentRequest::STATUSES, default: ClassEnrollmentRequest::REGISTERED, :include_blank => I18n.t("active_scaffold._select_")}


    config.actions.exclude :deleted_records
  end
end
