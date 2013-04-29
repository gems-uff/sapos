# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :scholarship_duration do
    enrollment
    scholarship
    start_date 2.days.ago
    end_date 2.days.from_now
  end
end
