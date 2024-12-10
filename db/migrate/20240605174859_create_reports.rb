class CreateReports < ActiveRecord::Migration[7.0]
  def change
    create_table :reports do |t|
      t.references :generated_by, foreign_key: { to_table: :users }
      t.references :carrierwave_file, foreign_key: { to_table: :carrier_wave_files }

      t.timestamps
    end
  end
end
