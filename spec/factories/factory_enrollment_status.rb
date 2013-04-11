# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :enrollment_status do
    sequence :name do |name|
      "EnrollmentStatus_#{name}"
    end
  end
end
