# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe ResearchArea, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:course_research_areas).dependent(:destroy) }
  it { should have_many(:courses).through(:course_research_areas) }
  it { should have_many(:enrollments).dependent(:restrict_with_exception) }
  it { should have_many(:professor_research_areas).dependent(:destroy) }
  it { should have_many(:professors).through(:professor_research_areas) }
  let(:research_area) do
    ResearchArea.new(
      name: "Engenharia de Software",
      code: "ES"
    )
  end
  subject { research_area }
  describe "Validations" do
    it { should be_valid }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:code) }
    it { should validate_presence_of(:code) }
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        research_area_code = "ResearchArea code"
        research_area_name = "ResearchArea name"
        research_area.code = research_area_code
        research_area.name = research_area_name
        expected = "#{research_area_code} - #{research_area_name}"
        expect(research_area.to_label).to eql(expected)
      end
    end
  end
end
