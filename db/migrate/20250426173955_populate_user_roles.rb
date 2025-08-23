class PopulateUserRoles < ActiveRecord::Migration[7.0]
  def up
    users_with_role = ActiveRecord::Base.connection.execute("SELECT id, role_id FROM users")

    users_with_role.each do |row|
      user_id = row[0]
      role_id = row[1]

      UserRole.create!(user_id: user_id, role_id: role_id) if role_id.present?
    end
  end

  def down
    UserRole.delete_all
  end
end
