# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe ProfessorResearchArea do
  let(:professor_research_area) { ProfessorResearchArea.new }
  subject { professor_research_area }
  describe "Validations" do
    describe "professor" do
      context "should be valid when" do
        it "professor is not null" do
          professor_research_area.professor = Professor.new
          professor_research_area.should have(0).errors_on :professor
        end
      end
      context "should have error blank when" do
        it "professor is null" do
          professor_research_area.professor = nil
          professor_research_area.should have_error(:blank).on :professor
        end
      end
    end
    describe "research_area" do
      context "should be valid when" do
        it "research_area is not null" do
          professor_research_area.research_area = ResearchArea.new
          professor_research_area.should have(0).errors_on :research_area
        end
      end
      context "should have error blank when" do
        it "professor is null" do
          professor_research_area.research_area = nil
          professor_research_area.should have_error(:blank).on :research_area
        end
      end
    end

    describe "professor_id" do
      context "should be valid when" do
        it "don't exists the professor for the same research_area" do
          professor_research_area.professor = Professor.new
          professor_research_area.should have(0).errors_on :professor_id
        end
      end
      context "should have uniqueness error when" do
        it "already exists the same professor for the same research_area" do
          professor_research_area.professor = FactoryGirl.create(:professor)
          professor_research_area.research_area = FactoryGirl.create(:research_area)
          FactoryGirl.create(:professor_research_area, :professor => professor_research_area.professor, :research_area => professor_research_area.research_area)
          professor_research_area.should have_error(:taken).on :professor_id
        end
      end
    end
  end
end