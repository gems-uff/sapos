# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :deferral_type do
    phase
    sequence :name do |i|
      "DeferralType_#{i}"
    end
    duration_semesters 1
    duration_months 1
    duration_days 1
  end
end
