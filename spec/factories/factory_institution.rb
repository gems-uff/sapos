# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :institution do
    sequence :name do |name|
      "Institution_#{name}"
    end
  end
end
