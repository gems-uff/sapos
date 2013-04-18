# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :class_enrollment do
    course_class
    enrollment
    situation ClassEnrollment::SITUATIONS.first
  end
end
