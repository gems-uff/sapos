# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :scholarship_type do
    sequence :name do |name|
      "ScholarshipType_#{name}"
    end
  end
end
