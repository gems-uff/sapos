# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :deferral do
    deferral_type
    enrollment
  end
end
