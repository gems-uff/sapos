class AddAcronymToInstitution < ActiveRecord::Migration
  def self.up
    add_column :institutions, :code, :string
  end

  def self.down
    remove_column :institutions, :code
  end
end
