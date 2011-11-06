class AddLevelToPhase < ActiveRecord::Migration
  def self.up
    add_column :phases, :level_id, :integer, :references => 'levels'
  end

  def self.down
    remove_column :phases, :level_id
  end
end
