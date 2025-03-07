class AddRefugeeOnStudent < ActiveRecord::Migration[7.0]
  def up
    add_column :students, :refugee, :string
  end
  def down
    remove_column :students, :refugee
  end

end
