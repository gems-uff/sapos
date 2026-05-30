# frozen_string_literal: true

require "spec_helper"

RSpec.describe CourseResearchLine, type: :model do
  before(:all) do
    @destroy_later = []
    @research_area = FactoryBot.create(:research_area)
    @course_type = FactoryBot.create(:course_type)
    @course = FactoryBot.create(:course, course_type: @course_type)
    @course_research_area = FactoryBot.create(:course_research_area, course: @course, research_area: @research_area)
    @research_line = FactoryBot.create(:research_line, research_area: @research_area)
  end

  after(:all) do
    @course_research_area.destroy
    @research_line.destroy
    @course.destroy
    @research_area.destroy
    @course_type.destroy
  end


  let(:course_research_line) do
    CourseResearchLine.new(
      course: @course,
      research_line: @research_line
    )
  end
  subject { course_research_line }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:course).required(true) }
    it { should belong_to(:research_line).required(true) }
    it { should validate_uniqueness_of(:course).scoped_to(:research_line_id).with_message(:unique_pair) }
  end
  describe "course_research_line" do
    it "should have error when the research_line's area is different of course's area" do
      @destroy_later << course = FactoryBot.create(:course)
      @destroy_later << research_area1 = FactoryBot.create(:research_area)
      @destroy_later << research_area2 = FactoryBot.create(:research_area)
      @destroy_later << research_line = FactoryBot.create(:research_line, research_area: research_area2)
      @destroy_later << FactoryBot.create(:course_research_area, course: course, research_area: research_area1)
      course_research_line.research_line = research_line
      course_research_line.course = course
      expect(course_research_line).not_to be_valid
    end
  end
end
