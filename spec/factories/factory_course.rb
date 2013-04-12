# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :course do
    course_type
    sequence :name do |name|
      "Course_#{name}"
    end
    sequence :code do |code|
      "#{code}"
    end
    credits 10
  end
end
