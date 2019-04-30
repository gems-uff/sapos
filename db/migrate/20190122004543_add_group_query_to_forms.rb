class AddGroupQueryToForms < ActiveRecord::Migration[5.1]
  def change
    add_column :forms, :group_query, :boolean
  end
end
