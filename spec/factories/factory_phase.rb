# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :phase do
    sequence :name do |name|
      "Phase_#{name}"
    end
  end
end
