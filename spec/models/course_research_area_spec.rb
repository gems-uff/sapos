# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe CourseResearchArea, type: :model do
  it { should be_able_to_be_destroyed }
  let(:course) { FactoryBot.build(:course) }
  let(:research_area) { FactoryBot.build(:research_area) }
  let(:course_research_area) do
    CourseResearchArea.new(
      course: course,
      research_area: research_area
    )
  end
  subject { course_research_area }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:course).required(true) }
    it { should belong_to(:research_area).required(true) }
    it { should validate_uniqueness_of(:course).scoped_to(:research_area_id).with_message(:unique_pair) }
  end
end
