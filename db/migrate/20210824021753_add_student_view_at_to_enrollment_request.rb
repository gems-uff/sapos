class AddStudentViewAtToEnrollmentRequest < ActiveRecord::Migration[6.0]
  def change
    add_column :enrollment_requests, :student_view_at, :datetime
  end
end
