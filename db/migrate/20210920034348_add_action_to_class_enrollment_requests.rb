class AddActionToClassEnrollmentRequests < ActiveRecord::Migration[6.0]
  def change
    add_column :class_enrollment_requests, :action, :string, default: "Adição"
  end
end
