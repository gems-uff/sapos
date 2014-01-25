# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :notification do
    to_template "sapos@mailinator.com"
    subject_template "test"
    body_template "test"
    sql_query "SELECT *"
    notification_offset 0
    query_offset 0
    frequency I18n.translate("activerecord.attributes.notification.frequencies.daily")
    title "test"
    
  end
end
