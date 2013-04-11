# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :dismissal_reason do
    sequence :name do |name|
      "DismissalReason_#{name}"
    end
  end
end
