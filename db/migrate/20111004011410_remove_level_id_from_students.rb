class RemoveLevelIdFromStudents < ActiveRecord::Migration
  def self.up
    remove_column :students, :level_id
  end

  def self.down
    add_column :students, :level_id, :integer, :references => "levels"
  end
end
