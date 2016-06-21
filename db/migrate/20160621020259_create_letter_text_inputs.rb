class CreateLetterTextInputs < ActiveRecord::Migration
  def change
    create_table :letter_text_inputs do |t|
      t.integer :letter_request_id
      t.integer :form_field_id
      t.text :input

      t.timestamps null: false
    end
    add_index :letter_text_inputs, :letter_request_id
    add_index :letter_text_inputs, :form_field_id
  end
end
