class CreateStudentTokens < ActiveRecord::Migration
  def change
    create_table :student_tokens do |t|
      t.integer :application_process_id
      t.integer :student_id
      t.string :token
      t.boolean :is_used

      t.timestamps null: false
    end
    add_index :student_tokens, :application_process_id
    add_index :student_tokens, :student_id
  end
end
