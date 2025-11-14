class CreateUserRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end
  end

  # reversible do |dir|
  #   dir.up do
  #     User.find_each do |user|
  #       UserRoles.create!(user: user, role: user.role)
  #     end
  #   end
  # end
end
