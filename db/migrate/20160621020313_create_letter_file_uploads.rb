class CreateLetterFileUploads < ActiveRecord::Migration
  def change
    create_table :letter_file_uploads do |t|
      t.integer :letter_request_id
      t.integer :form_field_id
      t.string :file

      t.timestamps null: false
    end
    add_index :letter_file_uploads, :letter_request_id
    add_index :letter_file_uploads, :form_field_id
  end
end
