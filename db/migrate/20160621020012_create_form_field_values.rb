class CreateFormFieldValues < ActiveRecord::Migration
  def change
    create_table :form_field_values do |t|
      t.integer :form_field_id
      t.string :value

      t.timestamps null: false
    end
    add_index :form_field_values, :form_field_id
  end
end
