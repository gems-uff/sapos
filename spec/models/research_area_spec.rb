# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe ResearchArea do
  let(:research_area) { ResearchArea.new }
  subject { research_area }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          research_area.name = "ResearchArea name"
          research_area.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          research_area.name = nil
          research_area.should have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "ResearchArea name"
          FactoryGirl.create(:research_area, :name => name)
          research_area.name = name
          research_area.should have_error(:taken).on :name
        end
      end
    end
    describe "code" do
      context "should be valid when" do
        it "code is not null and is not taken" do
          research_area.code = "ResearchArea code"
          research_area.should have(0).errors_on :code
        end
      end
      context "should have error blank when" do
        it "code is null" do
          research_area.code = nil
          research_area.should have_error(:blank).on :code
        end
      end
      context "should have error taken when" do
        it "code is already in use" do
          code = "ResearchArea code"
          FactoryGirl.create(:research_area, :code => code)
          research_area.code = code
          research_area.should have_error(:taken).on :code
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        research_area_code = "ResearchArea code"
        research_area_name = "ResearchArea name"
        research_area.code = research_area_code
        research_area.name = research_area_name
        expected = "#{research_area_code} - #{research_area_name}"
        research_area.to_label.should eql(expected)
      end
    end
  end
end