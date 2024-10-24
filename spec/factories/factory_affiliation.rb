# frozen_string_literal: true

FactoryBot.define do
  factory :affiliation do
    institution
    professor
    start_date { Time.now }
    end_date { Time.now }
  end
end
