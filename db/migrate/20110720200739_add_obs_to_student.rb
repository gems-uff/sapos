class AddObsToStudent < ActiveRecord::Migration
  def self.up
    add_column :students, :obs, :text
  end

  def self.down
    remove_column :students, :obs
  end
end
