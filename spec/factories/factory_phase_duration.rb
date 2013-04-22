# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :phase_duration do
    phase
    level
    deadline_semesters 1
    deadline_months 1
    deadline_days 1
  end
end
