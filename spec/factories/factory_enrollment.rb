# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :enrollment do
    student
    level
    enrollment_status
    sequence :enrollment_number do |number|
      number
    end
  end
end
