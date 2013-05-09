# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :level do
    sequence :name do |name|
      "Level_#{name}"
    end
  end
end
