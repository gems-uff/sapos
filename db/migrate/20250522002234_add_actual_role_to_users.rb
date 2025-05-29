class AddActualRoleToUsers < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :actual_role, :integer
    User.find_each do |user|
      actual_role = user.user_max_role
      user.update!(actual_role: actual_role) if actual_role
    end
  end

  def down
    remove_column :users, :actual_role, :integer
  end
end
