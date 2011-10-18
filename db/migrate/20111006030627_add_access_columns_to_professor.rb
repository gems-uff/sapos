class AddAccessColumnsToProfessor < ActiveRecord::Migration
  def self.up
    add_column :professors, :sex, :string
    add_column :professors, :civil_status, :string
    add_column :professors, :identity, :string
    add_column :professors, :identity_issuing_body, :string
    add_column :professors, :identity_expedition_date, :string
    add_column :professors, :neighbourhood, :string
    add_column :professors, :address, :string
    add_column :professors, :state_id, :integer, :references => 'states'
    add_column :professors, :city_id, :integer, :references => 'cities'
    add_column :professors, :zip_code, :string
    add_column :professors, :telephone1, :string
    add_column :professors, :telephone2, :string
    add_column :professors, :siape, :string
  end

  def self.down
    remove_column :professors, :siape
    remove_column :professors, :telephone2
    remove_column :professors, :telephone1
    remove_column :professors, :zip_code
    remove_column :professors, :city_id
    remove_column :professors, :state_id
    remove_column :professors, :address
    remove_column :professors, :neighbourhood
    remove_column :professors, :identity_expedition_date
    remove_column :professors, :identity_issuing_body
    remove_column :professors, :identity
    remove_column :professors, :civil_status
    remove_column :professors, :sex
  end
end
