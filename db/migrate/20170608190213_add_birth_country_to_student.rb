class AddBirthCountryToStudent < ActiveRecord::Migration
  def change
    add_column :students, :birth_country_id, :integer
    add_index :students, :birth_country_id
  end
end
