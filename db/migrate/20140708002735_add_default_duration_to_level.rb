class AddDefaultDurationToLevel < ActiveRecord::Migration
  def change
    add_column :levels, :default_duration, :integer, :default => 0
  end
end
