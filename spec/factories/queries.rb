# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :query do
    name "MyString"
    sql "MyText"
  end
end
