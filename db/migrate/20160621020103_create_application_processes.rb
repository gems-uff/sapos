class CreateApplicationProcesses < ActiveRecord::Migration
  def change
    create_table :application_processes do |t|
      t.string :name
      t.integer :semester
      t.integer :year
      t.date :start_date
      t.date :end_date
      t.integer :form_template_id
      t.integer :letter_template_id
      t.integer :min_letters
      t.integer :max_letter

      t.timestamps null: false
    end
    add_index :application_processes, :form_template_id
    add_index :application_processes, :letter_template_id
  end
end
