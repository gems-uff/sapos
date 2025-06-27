# frozen_string_literal: true

class UserRole < ApplicationRecord
  has_paper_trail

  belongs_to :role, optional: false
  belongs_to :user, optional: false

  validates :role, presence: true
  validates :role, presence: true

  def to_label
    "#{self.user.name} - #{self.role.name}"
  end
end
