class AddFieldOfStudyToEnrollment < ActiveRecord::Migration
  def change
    add_column :enrollments, :field_of_study, :string
  end
end
