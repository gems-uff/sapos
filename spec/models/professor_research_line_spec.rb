# frozen_string_literal: true

require "spec_helper"

RSpec.describe ProfessorResearchLine, type: :model do
  before(:all) do
    @research_area = FactoryBot.create(:research_area)
    @professor = FactoryBot.create(:professor)
    @professor_research_area = FactoryBot.create(:professor_research_area, professor: @professor, research_area: @research_area)
    @research_line = FactoryBot.create(:research_line, research_area: @research_area)
    @destroy_later = []
  end

  after(:all) do
    @professor_research_area.destroy
    @research_line.destroy
    @professor.destroy
    @research_area.destroy
  end


  let(:professor_research_line) do
    ProfessorResearchLine.new(
      professor: @professor,
      research_line: @research_line
    )
  end
  subject { professor_research_line }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:professor).required(true) }
    it { should belong_to(:research_line).required(true) }
    it { should validate_uniqueness_of(:professor).scoped_to(:research_line_id).with_message(:unique_pair) }
  end

  describe "professor_research_line" do
    it "should have error when the research_line's area is different of professor's area" do
      @destroy_later << professor = FactoryBot.create(:professor)
      @destroy_later << research_area1 = FactoryBot.create(:research_area)
      @destroy_later << research_area2 = FactoryBot.create(:research_area)
      @destroy_later << research_line = FactoryBot.create(:research_line, research_area: research_area2)
      @destroy_later << FactoryBot.create(:professor_research_area, professor: professor, research_area: research_area1)
      professor_research_line.research_line = research_line
      professor_research_line.professor = professor
      expect(professor_research_line).not_to be_valid
    end
  end
end
