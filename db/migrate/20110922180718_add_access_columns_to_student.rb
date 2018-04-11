# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddAccessColumnsToStudent < ActiveRecord::Migration[5.1]
  def self.up
    add_column :students, :birthdate, :date
    add_column :students, :sex, :string
    add_column :students, :civil_status, :string
    add_column :students, :father_name, :string
    add_column :students, :mother_name, :string
    add_column :students, :country_id, :integer, :references => 'countries'
    add_column :students, :birthplace, :integer, :references => 'states'
    add_column :students, :identity_number, :string
    add_column :students, :identity_issuing_body, :string
    add_column :students, :identity_expedition_date, :date
    add_column :students, :employer, :string
    add_column :students, :job_position, :string
    add_column :students, :level_id, :integer, :references => 'levels'
    add_column :students, :state_id, :integer, :references => 'states'
    add_column :students, :city_id, :integer, :references => 'cities'
    add_column :students, :neighbourhood, :string
    add_column :students, :zip_code, :string
    add_column :students, :address, :string
    add_column :students, :telephone1, :string
    add_column :students, :telephone2, :string
    add_column :students, :email, :string
  end

  def self.down
    remove_column :students, :email
    remove_column :students, :telephone2
    remove_column :students, :telephone1
    remove_column :students, :address
    remove_column :students, :zip_code
    remove_column :students, :neighbourhood
    remove_column :students, :city_id
    remove_column :students, :state_id
    remove_column :students, :level_id
    remove_column :students, :job_position
    remove_column :students, :employer
    remove_column :students, :identity_expedition_date
    remove_column :students, :identity_issuing_body
    remove_column :students, :identity_number
    remove_column :students, :birthplace
    remove_column :students, :country_id
    remove_column :students, :mother_name
    remove_column :students, :father_name
    remove_column :students, :civil_status
    remove_column :students, :sex
    remove_column :students, :birthdate
  end
end
