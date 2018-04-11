class ChangeColumnTypeOfObjectInVersions < ActiveRecord::Migration[5.1]
  def change
    change_column :versions, :object, :text, :limit => 16777215	  
  end
end
