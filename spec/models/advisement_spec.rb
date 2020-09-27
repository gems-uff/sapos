# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Advisement do
  let(:advisement) { Advisement.new }
  subject { advisement }
  describe "Validations" do
    describe "enrollment" do
      context "should be valid when" do
        it "enrollment is not null" do
          advisement.enrollment = Enrollment.new
          expect(advisement).to have(0).errors_on :enrollment
        end
      end
      context "should have error blank when" do
        it "enrollment is null" do
          advisement.enrollment = nil
          expect(advisement).to have_error(:blank).on :enrollment
        end
      end
    end
    describe "professor" do
      context "should be valid when" do
        it "professor is not null" do
          advisement.professor = Professor.new
          expect(advisement).to have(0).errors_on :professor
        end
      end
      context "should have error blank when" do
        it "professor is null" do
          advisement.professor = nil
          expect(advisement).to have_error(:blank).on :professor
        end
      end
    end
    describe "main_advisor" do
      context "should be valid when" do
        it "have other advisor" do
          allow(advisement).to receive(:enrollment_has_advisors).and_return(true)
          advisement.main_advisor = nil
          expect(advisement).to have(0).errors_on :main_advisor
        end
        it "does not have other advisor and main_advisor is true" do
          allow(advisement).to receive(:enrollment_has_advisors).and_return(false)
          advisement.main_advisor = true
          expect(advisement).to have(0).errors_on :main_advisor
        end
      end
    end
    describe "professor_id" do
      context "should be valid when" do
        it "don't exists another advisement for the same enrollment" do
          advisement.professor = Professor.new
          expect(advisement).to have(0).errors_on :professor_id
        end
      end
      context "should have uniqueness error when" do
        it "already exists another advisement for the same enrollment" do
          advisement.professor = FactoryBot.create(:professor)
          advisement.enrollment = FactoryBot.create(:enrollment)
          FactoryBot.create(:advisement, :professor => advisement.professor, :enrollment => advisement.enrollment)
          expect(advisement).to have_error(:advisement_professor_uniqueness).on :professor_id
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        enrollment_number = "123"
        professor_name = "professor"
        advisement.enrollment = Enrollment.new(:enrollment_number => enrollment_number)
        advisement.professor = Professor.new(:name => professor_name)
        expect(advisement.to_label).to eql("#{enrollment_number} - #{professor_name}")
      end
    end
    describe "co_advisor_list" do
      it "should return the expected string" do
        professor1_name = "Leonardo"
        professor2_name = "Vanessa"
        professor1 = FactoryBot.create(:professor, :name => professor1_name)
        professor2 = FactoryBot.create(:professor, :name => professor2_name)
        advisement = FactoryBot.create(:advisement)
        FactoryBot.create(:advisement, :professor => professor1, :enrollment => advisement.enrollment, :main_advisor => false)
        FactoryBot.create(:advisement, :professor => professor2, :enrollment => advisement.enrollment, :main_advisor => false)
        expect(advisement.co_advisor_list).to eql("#{professor1_name} , #{professor2_name}")
      end
    end
    describe "active" do
      context "should return true when " do
        it "the enrollment does not have a dismissal" do
          advisement = FactoryBot.create(:advisement)
          expect(advisement.active).to be_truthy
        end
      end
      context "should return false when " do
        it "the enrollment have a dismissal" do
          advisement = FactoryBot.create(:advisement)
          FactoryBot.create(:dismissal, :enrollment => advisement.enrollment)
          expect(advisement.active).to be_falsey
        end
      end
    end
    describe "co_advisor" do
      context "should return true when " do
        it "the enrollment have another advisement" do
          other_advisement = FactoryBot.create(:advisement)
          FactoryBot.create(:advisement, :enrollment => other_advisement.enrollment, :main_advisor => false)
          expect(other_advisement.co_advisor).to be_truthy
        end
      end
      context "should return false when " do
        it "the enrollment does not have another advisement" do
          advisement = FactoryBot.create(:advisement)
          expect(advisement.co_advisor).to be_falsey
        end
      end
    end
    describe "enrollment_has_advisors" do
      context "should return true when " do
        it "the enrollment have one advisement" do
          advisement = FactoryBot.create(:advisement)
          expect(advisement.enrollment_has_advisors).to be_truthy
        end
      end
      context "should return false when " do
        it "the enrollment does not have any advisements" do
          advisement.enrollment = FactoryBot.create(:enrollment)
          expect(advisement.enrollment_has_advisors).to be_falsey
        end
      end
    end
  end
end
