# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :dismissal do
    dismissal_reason
    enrollment
    date Date.today
  end
end
