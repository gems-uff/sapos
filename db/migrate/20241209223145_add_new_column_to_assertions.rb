class AddNewColumnToAssertions < ActiveRecord::Migration[7.0]
  def change
    add_column :assertions, :assertion_template, :text
  end
end