class CreateFormFileUploads < ActiveRecord::Migration
  def change
    create_table :form_file_uploads do |t|
      t.integer :student_application_id
      t.integer :form_field_id
      t.string :file

      t.timestamps null: false
    end
    add_index :form_file_uploads, :student_application_id
    add_index :form_file_uploads, :form_field_id
  end
end
