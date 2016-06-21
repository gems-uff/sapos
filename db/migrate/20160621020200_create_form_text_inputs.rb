class CreateFormTextInputs < ActiveRecord::Migration
  def change
    create_table :form_text_inputs do |t|
      t.integer :student_application_id
      t.integer :form_field_id
      t.text :input

      t.timestamps null: false
    end
    add_index :form_text_inputs, :student_application_id
    add_index :form_text_inputs, :form_field_id
  end
end
