# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :course_class do
    course
    professor
    year "2013"
    semester "1"
  end
end
