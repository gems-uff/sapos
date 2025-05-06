# frozen_string_literal: true

class UserRole < ApplicationRecord
  has_paper_trail

  belongs_to :role, optional: false
  belongs_to :user, optional: false

  validates :role, presence: true
  validates :role, presence: true


  # def self.max_role_priority(user)
  #   roles = where(user: user).pluck(:role_id)
  #   if roles.present?
  #     highest_role = roles[0]
  #     for role in roles
  #       if Role::ORDER.index(highest_role) < Role::ORDER.index(role)
  #         highest_role = role
  #       end
  #     end
  #     highest_role
  #   end
  # end
end
