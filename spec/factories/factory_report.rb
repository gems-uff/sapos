# frozen_string_literal: true

FactoryBot.define do
  factory :report do
    association :user, factory: :user
    file_name { "report_#{SecureRandom.hex(4)}.pdf" }
    created_at { Time.now }
    expires_at { 1.year.from_now }
  end
end
