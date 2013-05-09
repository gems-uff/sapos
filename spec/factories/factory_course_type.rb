# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :course_type do
    sequence :name do |name|
      "CourseType_#{name}"
    end
  end
end
