class CreateFormFieldInputs < ActiveRecord::Migration
  def change
    create_table :form_field_inputs do |t|
      t.integer :student_application_id
      t.integer :form_field_id
      t.string :input

      t.timestamps null: false
    end
    add_index :form_field_inputs, :student_application_id
    add_index :form_field_inputs, :form_field_id
  end
end
