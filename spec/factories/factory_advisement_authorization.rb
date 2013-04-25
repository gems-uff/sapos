# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :advisement_authorization do
    professor
    level
  end
end
