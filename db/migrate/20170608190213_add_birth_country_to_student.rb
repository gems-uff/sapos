class AddBirthCountryToStudent < ActiveRecord::Migration
  def change
    add_reference :students, :birth_country, index: true, foreign_key: true
  end
end
