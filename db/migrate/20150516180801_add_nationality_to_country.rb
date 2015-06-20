class AddNationalityToCountry < ActiveRecord::Migration
  def change
  	add_column :countries, :nationality, :string, :default => "-"
  end
end
