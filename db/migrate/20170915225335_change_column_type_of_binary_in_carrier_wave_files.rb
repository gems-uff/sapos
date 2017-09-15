class ChangeColumnTypeOfBinaryInCarrierWaveFiles < ActiveRecord::Migration
  def change
    change_column :carrier_wave_files, :binary, :binary, :limit => 16777215	  
  end
end
