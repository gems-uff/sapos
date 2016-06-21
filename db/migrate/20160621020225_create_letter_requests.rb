class CreateLetterRequests < ActiveRecord::Migration
  def change
    create_table :letter_requests do |t|
      t.integer :student_application_id
      t.string :professor_name
      t.string :professor_email
      t.string :professor_telephone
      t.string :access_token
      t.boolean :is_filled

      t.timestamps null: false
    end
    add_index :letter_requests, :student_application_id
  end
end
