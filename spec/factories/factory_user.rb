# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    sequence :name do |name|
      "User_#{name}"
    end
    hashed_password "password"
  end
end
