class AddUserToEnrollmentStatuses < ActiveRecord::Migration[6.0]
  def change
    add_column :enrollment_statuses, :user, :boolean
  end
end
