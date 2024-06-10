class CreateSkinColor < ActiveRecord::Migration[7.0]
  def up
    create_table :skin_colors do |t|
      t.string :name
      t.string :description

      t.timestamps
    end
    add_column :students, :skin_color_id, :integer
    add_foreign_key :students, :skin_colors, name: "skin_color_id"
  end
  def down
    drop_table :skin_colors
    remove_column :students, :skin_color_id
    remove_foreign_key :students, :skin_colors
  end
end
