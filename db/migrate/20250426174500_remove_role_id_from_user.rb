class RemoveRoleIdFromUser < ActiveRecord::Migration[7.0]
  def up
    remove_column :users, :role_id, :integer
  end

  def down
    add_column :users, :role_id, :integer, default: 1

    User.find_each do |user|
      user.update!(role_id: user.user_max_role)
    end
  end
end
