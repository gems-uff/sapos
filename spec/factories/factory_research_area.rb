# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :research_area do
    sequence :name do |name|
      "ResearchArea_#{name}"
    end
    sequence :code do |code|
      "ResearchArea_#{code}"
    end
  end
end
