class AddBoxDimensionsToAssertions < ActiveRecord::Migration[7.0]
  def change
    add_column :assertions, :assertion_box_width, :integer, default: 400
    add_column :assertions, :assertion_box_height, :integer, default: 500
  end
end
