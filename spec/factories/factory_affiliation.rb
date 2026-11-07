# frozen_string_literal: true

FactoryBot.define do
  factory :affiliation do
    institution
    professor
    start_date { Time.current }
    end_date { Time.current }
  end
end
