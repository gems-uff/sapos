class AddRoleIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :role_id, :integer, :null => false, :default => 1
  end

  def self.down
    remove_column :users, :role_id
  end
end
