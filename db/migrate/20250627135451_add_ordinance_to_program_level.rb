class AddOrdinanceToProgramLevel < ActiveRecord::Migration[7.0]
  def change
    add_column :program_levels, :ordinance, :string
  end
end
