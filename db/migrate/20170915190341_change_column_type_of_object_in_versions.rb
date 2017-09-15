class ChangeColumnTypeOfObjectInVersions < ActiveRecord::Migration
  def change
    change_column :versions, :object, :text, :limit => 16777215	  
  end
end
