# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :advisement do
    professor
    enrollment
    main_advisor true
  end
end
