class AddStudentApplicationIdToStudentToken < ActiveRecord::Migration
  def change
    add_column :student_tokens, :student_application_id, :integer
    add_index :student_tokens, :student_application_id
  end
end
