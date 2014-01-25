# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :notification do
    to_template "sapos@mailinator.com"
    subject_template "test"
    body_template "test"
    sql_query "SELECT *"
    notification_offset 10
    query_offset 10
    frequency "daily"
  end
end
