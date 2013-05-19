# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    sequence :name do |name|
      "User_#{name}"
    end
    password "password"
    role_id Role::ROLE_ADMINISTRADOR
  end
end
