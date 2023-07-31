# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Advisement, type: :model do
  it { should be_able_to_be_destroyed }

  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end

  let(:professor) { FactoryBot.build(:professor) }
  let(:enrollment) { FactoryBot.build(:enrollment) }
  let(:advisement) do
    Advisement.new(
      professor: professor,
      enrollment: enrollment
    )
  end
  subject { advisement }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:professor).required(true) }
    it { should belong_to(:enrollment).required(true) }
    it { should validate_uniqueness_of(:professor).scoped_to(:enrollment_id).with_message(:advisement_professor_uniqueness) }

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
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        enrollment_number = "123"
        professor_name = "professor"
        advisement.enrollment = Enrollment.new(enrollment_number: enrollment_number)
        advisement.professor = Professor.new(name: professor_name)
        expect(advisement.to_label).to eql("#{enrollment_number} - #{professor_name}")
      end
    end
    describe "co_advisor_list" do
      it "should return the expected string" do
        professor1_name = "Leonardo"
        professor2_name = "Vanessa"
        @destroy_later << professor1 = FactoryBot.create(:professor, name: professor1_name)
        @destroy_later << professor2 = FactoryBot.create(:professor, name: professor2_name)
        @destroy_later << advisement = FactoryBot.create(:advisement)
        @destroy_later << FactoryBot.create(:advisement, professor: professor1, enrollment: advisement.enrollment, main_advisor: false)
        @destroy_later << FactoryBot.create(:advisement, professor: professor2, enrollment: advisement.enrollment, main_advisor: false)
        expect(advisement.co_advisor_list).to eql("#{professor1_name} , #{professor2_name}")
      end
    end
    describe "active" do
      context "should return true when " do
        it "the enrollment does not have a dismissal" do
          @destroy_later << advisement = FactoryBot.create(:advisement)
          expect(advisement.active).to be_truthy
        end
      end
      context "should return false when " do
        it "the enrollment have a dismissal" do
          @destroy_later << advisement = FactoryBot.create(:advisement)
          @destroy_later << FactoryBot.create(:dismissal, enrollment: advisement.enrollment)
          expect(advisement.active).to be_falsey
        end
      end
    end
    describe "co_advisor" do
      context "should return true when " do
        it "the enrollment have another advisement" do
          @destroy_later << other_advisement = FactoryBot.create(:advisement)
          @destroy_later << FactoryBot.create(:advisement, enrollment: other_advisement.enrollment, main_advisor: false)
          expect(other_advisement.co_advisor).to be_truthy
        end
      end
      context "should return false when " do
        it "the enrollment does not have another advisement" do
          @destroy_later << advisement = FactoryBot.create(:advisement)
          expect(advisement.co_advisor).to be_falsey
        end
      end
    end
    describe "enrollment_has_advisors" do
      context "should return true when " do
        it "the enrollment have one advisement" do
          @destroy_later << advisement = FactoryBot.create(:advisement)
          expect(advisement.enrollment_has_advisors).to be_truthy
        end
      end
      context "should return false when " do
        it "the enrollment does not have any advisements" do
          @destroy_later << advisement.enrollment = FactoryBot.create(:enrollment)
          expect(advisement.enrollment_has_advisors).to be_falsey
        end
      end
    end
  end
end
