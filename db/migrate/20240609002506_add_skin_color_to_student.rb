class AddSkinColorToStudent < ActiveRecord::Migration[7.0]
  def up
    add_column :students, :skin_color, :string
    add_column :students, :pcd, :string
  end
  def down
    remove_column :students, :skin_color
    remove_column :students, :pcd
  end
end
