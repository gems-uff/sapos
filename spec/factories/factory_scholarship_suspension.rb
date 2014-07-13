# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :scholarship_suspension do
    start_date 1.days.ago
    end_date 1.days.from_now
    active true
    scholarship_duration
  end
end
