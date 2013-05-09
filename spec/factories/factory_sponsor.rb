# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sponsor do
    sequence :name do |name|
      "Sponsor_#{name}"
    end
  end
end
