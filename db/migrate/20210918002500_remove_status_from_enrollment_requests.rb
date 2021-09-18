class RemoveStatusFromEnrollmentRequests < ActiveRecord::Migration[6.0]
  def change
    remove_column :enrollment_requests, :status
  end
end
