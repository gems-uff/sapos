# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :thesis_defense_committee_participation do
    professor
    enrollment
  end
end
