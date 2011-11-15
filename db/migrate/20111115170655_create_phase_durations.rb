class CreatePhaseDurations < ActiveRecord::Migration
  def self.up
    create_table :phase_durations do |t|
      t.references :phase
      t.references :level
      t.integer :deadline

      t.timestamps
    end
  end

  def self.down
    drop_table :phase_durations
  end
end
