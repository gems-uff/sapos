# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :query_param do
    query nil
    default_value "MyString"
    value_type "MyString"
  end
end
