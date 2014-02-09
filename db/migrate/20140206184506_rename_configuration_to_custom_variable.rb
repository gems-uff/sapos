class RenameConfigurationToCustomVariable < ActiveRecord::Migration
  def up
  	rename_table :configurations, :custom_variables
  end

  def down
  	rename_table :custom_variables, :configurations
  end
end
