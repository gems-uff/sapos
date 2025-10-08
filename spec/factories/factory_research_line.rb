# frozen_string_literal: true

FactoryBot.define do
  factory :research_line do
    sequence :name do |name|
      "ResearchLine_#{name}"
    end
    sequence :code do |code|
      "ResearchLine_#{code}"
    end
    research_area
    available { true }
  end
end
