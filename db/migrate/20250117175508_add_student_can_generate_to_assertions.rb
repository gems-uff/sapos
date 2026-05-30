class AddStudentCanGenerateToAssertions < ActiveRecord::Migration[7.0]
  def up
    add_column :assertions, :student_can_generate, :boolean, default: false
  end

  def down
    remove_column :assertions, :student_can_generate
  end
end
