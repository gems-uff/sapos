class RenameCustomVariablesNameToDescription < ActiveRecord::Migration
  def change
  	rename_column :custom_variables, :name, :description
  end
end
