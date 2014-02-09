# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Accomplishment do
  let(:accomplishment) { Accomplishment.new }
  subject { accomplishment }
  describe "Validations" do
    describe "enrollment" do
      context "should be valid when" do
        it "enrollment is not null" do
          accomplishment.enrollment = Enrollment.new
          accomplishment.should have(0).errors_on :enrollment
        end

        it "phase has the enrollment level" do
          level = FactoryGirl.create(:level)
          phase = FactoryGirl.create(:phase)
          accomplishment.enrollment = FactoryGirl.create(:enrollment, :level => level)
          accomplishment.phase = phase
          phase_duration = FactoryGirl.create(:phase_duration, :phase => phase, :level => level)
          
          accomplishment.should have(0).errors_on :enrollment
        end
      end
      context "should have error blank when" do
        it "enrollment is null" do
          accomplishment.enrollment = nil
          accomplishment.should have_error(:blank).on :enrollment
        end
      end
      context "should have error enrollment_level when" do
        it "phase phase doesn't have the enrollment level" do
          level = FactoryGirl.create(:level)
          phase = FactoryGirl.create(:phase)
          accomplishment.enrollment = FactoryGirl.create(:enrollment, :level => level)
          accomplishment.phase = phase
          
          accomplishment.should have_error(:enrollment_level).on :enrollment
        end
      end
    end
    describe "phase" do
      context "should be valid when" do
        it "phase is not null" do
          accomplishment.phase = Phase.new
          accomplishment.should have(0).errors_on :phase
        end
      end
      context "should have error blank when" do
        it "phase is null" do
          accomplishment.phase = nil
          accomplishment.should have_error(:blank).on :phase
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        phase_name = "Accomplished Phase"
        accomplishment.phase = Phase.new(:name => phase_name)
        accomplishment.to_label.should eql(phase_name)
      end
    end
  end
end