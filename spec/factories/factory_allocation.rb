# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :allocation do
    day { I18n.translate("date.day_names").first }
    course_class
    start_time 10
    end_time 12
  end
end
