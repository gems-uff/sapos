
# frozen_string_literal: true

module UserHelpers
  def delete_users_by_emails(emails)
    emails.each do |email|
      user = User.find_by_email(email)
      user.delete unless user.nil?
    end
  end

  def create_confirmed_user(roles, email = "user@ic.uff.br", name = "ana", password = "A1b2c3d4!", **kwargs)
    user = User.create(
      roles: roles,
      email: email,
      name: name,
      password: password,
      **kwargs
    )
    user.skip_confirmation!
    user.save!
    user
  end
end
