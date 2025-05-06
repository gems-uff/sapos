class AddActualRoleToUsers < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :actual_role, :integer
    User.find_each do |user|
      actual_role_id = user.user_max_role
      user.update!(actual_role: actual_role_id) if actual_role_id
    end
  end

  def down
    remove_column :users, :actual_role, :integer
  end
end
