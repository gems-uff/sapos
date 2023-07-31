
# frozen_string_literal: true

module UserHelpers
  def delete_users_by_emails(emails)
    emails.each do |email|
      user = User.find_by_email(email)
      user.delete unless user.nil?
    end
  end
end
