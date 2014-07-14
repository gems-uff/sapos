# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :enrollment_hold do
    enrollment
    year YearSemester.current.year
    semester YearSemester.current.semester
    number_of_semesters 1
  end
end
