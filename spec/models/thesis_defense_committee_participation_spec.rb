# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'spec_helper'

describe ThesisDefenseCommitteeParticipation do
let(:thesis_defense_committee_participation) { ThesisDefenseCommitteeParticipation.new }
  subject { thesis_defense_committee_participation }
  describe "Validations" do
    describe "enrollment" do
      context "should be valid when" do
        it "enrollment is not null" do
          thesis_defense_committee_participation.enrollment = Enrollment.new
          thesis_defense_committee_participation.should have(0).errors_on :enrollment
        end
      end
      context "should have error blank when" do
        it "enrollment is null" do
          thesis_defense_committee_participation.enrollment = nil
          thesis_defense_committee_participation.should have_error(:blank).on :enrollment
        end
      end
    end
    describe "professor" do
      context "should be valid when" do
        it "professor is not null" do
          thesis_defense_committee_participation.professor = Professor.new
          thesis_defense_committee_participation.should have(0).errors_on :professor
        end
      end
      context "should have error blank when" do
        it "professor is null" do
          thesis_defense_committee_participation.professor = nil
          thesis_defense_committee_participation.should have_error(:blank).on :professor
        end
      end
    end
    
    describe "professor_id" do
      context "should be valid when" do
        it "don't exists another advisement for the same enrollment" do
          thesis_defense_committee_participation.professor = Professor.new
          thesis_defense_committee_participation.should have(0).errors_on :professor_id
        end
      end
      context "should have uniqueness error when" do
        it "already exists another advisement for the same enrollment" do
          thesis_defense_committee_participation.professor = FactoryGirl.create(:professor)
          thesis_defense_committee_participation.enrollment = FactoryGirl.create(:enrollment)
          FactoryGirl.create(:thesis_defense_committee_participation, :professor => thesis_defense_committee_participation.professor, :enrollment => thesis_defense_committee_participation.enrollment)
          thesis_defense_committee_participation.should have_error(:thesis_defense_committee_participation_professor_uniqueness).on :professor_id
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        enrollment_number = "123"
        professor_name = "professor"
        thesis_defense_committee_participation.enrollment = Enrollment.new(:enrollment_number => enrollment_number)
        thesis_defense_committee_participation.professor = Professor.new(:name => professor_name)
        thesis_defense_committee_participation.to_label.should eql("#{enrollment_number} - #{professor_name}")
      end
    end
  end
end
