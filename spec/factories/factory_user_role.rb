# frozen_string_literal: true

FactoryBot.define do
  factory :user_role do
    user
    role
  end
end
