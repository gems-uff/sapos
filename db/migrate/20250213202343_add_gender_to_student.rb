class AddGenderToStudent < ActiveRecord::Migration[7.0]
  def up
    add_column :students, :gender, :string
  end
  def down
    remove_column :students, :gender
  end
end
