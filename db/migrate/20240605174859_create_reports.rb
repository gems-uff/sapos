class CreateReports < ActiveRecord::Migration[7.0]
  def change
    create_table :reports do |t|
      t.integer :generated_by_id
      t.integer :carrierwave_file_id

      t.foreign_key :users, column: :generated_by_id
      t.foreign_key :carrier_wave_files, column: :carrierwave_file_id

      t.timestamps
    end
  end
end
