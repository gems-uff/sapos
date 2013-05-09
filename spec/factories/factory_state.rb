# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :state do
    sequence :name do |name|
      "State_#{name}"
    end
    sequence :code do |code|
      "State_#{code}"
    end
    country
  end
end
