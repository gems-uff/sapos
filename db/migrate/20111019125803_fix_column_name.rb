class FixColumnName < ActiveRecord::Migration
  def self.up
    rename_column :professors, :identity, :identity_number
  end

  def self.down
  end
end
