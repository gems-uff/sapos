class AddObs < ActiveRecord::Migration[7.0]
  def up
    add_column :students, :obs_pcd, :text
    add_column :students, :obs_refugee, :text
  end
  def down
    remove_column :students, :obs_pcd
    remove_column :students, :obs_refugee
  end
end
