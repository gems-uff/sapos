# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :scholarship do
    sponsor
    level
    sequence :scholarship_number do |number|
      number
    end
  end
end
