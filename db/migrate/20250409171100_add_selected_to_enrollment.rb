class AddSelectedToEnrollment < ActiveRecord::Migration[7.0]
  def up
    add_column :enrollments, :admission_selection, :string
  end
  def down
    remove_column :enrollments, :admission_selection
  end
end
