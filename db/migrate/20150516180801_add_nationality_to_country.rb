class AddNationalityToCountry < ActiveRecord::Migration[5.1]
  def change
  	add_column :countries, :nationality, :string, :default => "-"
  end
end
