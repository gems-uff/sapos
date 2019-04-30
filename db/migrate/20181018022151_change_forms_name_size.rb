class ChangeFormsNameSize < ActiveRecord::Migration[5.1]
  def change
    change_column :forms, :nome, :string, :limit => 100
  end
end
