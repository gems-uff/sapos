# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :allocation do
    day { I18n.translate("date.day_names").first }
    course_class
    start_time {Time.now.at_beginning_of_day + 10.hours}
    end_time {Time.now.at_beginning_of_day + 12.hours}
  end
end
