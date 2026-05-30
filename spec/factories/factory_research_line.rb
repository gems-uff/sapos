# frozen_string_literal: true

FactoryBot.define do
  factory :research_line do
    sequence :name do |name|
      "ResearchLine_#{name}"
    end
    research_area
    available { true }
  end
end
