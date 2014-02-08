class ChangeCustomVariableValueType < ActiveRecord::Migration
  def up
  	change_column :custom_variables, :value, :text
  end

  def down
  	change_column :custom_variables, :value, :string
  end
end
