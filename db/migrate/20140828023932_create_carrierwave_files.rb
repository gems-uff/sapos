class CreateCarrierwaveFiles < ActiveRecord::Migration
  def change
    create_table :carrier_wave_files do |t|
      t.string :id
      t.string :medium_hash
      t.binary :binary

      t.timestamps
    end
  end
end
