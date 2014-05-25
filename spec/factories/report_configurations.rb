# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :report_configuration do
    name "MyString"
    use_at_report false
    use_at_transcript false
    use_at_grades_report false
    use_at_schedule false
    text "MyText"
    image "MyString"
    show_sapos false
  end
end
