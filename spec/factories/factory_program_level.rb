# frozen_string_literal: true

FactoryBot.define do
  factory :program_level do
    sequence(:level)
    start_date { Time.now }
    end_date { nil }
  end
end
