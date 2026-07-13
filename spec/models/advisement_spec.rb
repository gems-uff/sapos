# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Advisement, type: :model do
  it "should be able to be destroyed" do
    level = FactoryBot.create(:level)
    professor = FactoryBot.create(:professor)
    enrollment = FactoryBot.create(:enrollment, level: level)
    FactoryBot.create(:advisement_authorization, professor: professor, level: level)
    advisement = FactoryBot.create(:advisement, professor: professor, enrollment: enrollment)
    expect { advisement.destroy }.not_to raise_error
    expect(advisement.destroyed?).to be true
    [level, professor, enrollment].each(&:delete)
  end

  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end

  let(:level) { FactoryBot.build(:level) }
  let(:professor) do
    prof = FactoryBot.build(:professor)
    prof.advisement_authorizations.build(level: level)
    prof
  end
  let(:enrollment) { FactoryBot.build(:enrollment, level: level) }
  let(:advisement) do
    Advisement.new(
      professor: professor,
      enrollment: enrollment,
      main_advisor: true
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

    describe "enrollment_has_main_advisor" do
      it "should have error when no advisor is main advisor" do
        @destroy_later << level = FactoryBot.create(:level)
        @destroy_later << professor1 = FactoryBot.create(:professor)
        @destroy_later << enrollment = FactoryBot.create(:enrollment, level: level)
        @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor1, level: level)
        advisement = Advisement.new(professor: professor1, enrollment: enrollment, main_advisor: false)
        expect(advisement).to have_error(:main_advisor_required).on(:base)
      end

      it "should have error when more than one advisor is main advisor" do
        @destroy_later << level = FactoryBot.create(:level)
        @destroy_later << professor1 = FactoryBot.create(:professor)
        @destroy_later << professor2 = FactoryBot.create(:professor)
        @destroy_later << enrollment = FactoryBot.create(:enrollment, level: level)
        @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor1, level: level)
        @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor2, level: level)
        @destroy_later << FactoryBot.create(:advisement, professor: professor1, enrollment: enrollment, main_advisor: true)
        enrollment.reload
        advisement = Advisement.new(professor: professor2, enrollment: enrollment, main_advisor: true)
        expect(advisement).to have_error(:main_advisor_uniqueness).on(:base)
      end
    end

    describe "enrollment_has_authorized_advisor" do
      it "should have error when advisor does not have authorization at enrollment level" do
        @destroy_later << level = FactoryBot.create(:level)
        @destroy_later << professor1 = FactoryBot.create(:professor)
        @destroy_later << enrollment = FactoryBot.create(:enrollment, level: level)
        advisement = Advisement.new(professor: professor1, enrollment: enrollment, main_advisor: true)
        expect(advisement).to have_error(:no_advisor_with_level).on(:base)
      end

      it "should not have error when the accreditation validation is disabled" do
        @destroy_later << CustomVariable.create!(variable: :enable_advisor_accreditation_validation, value: "no")
        @destroy_later << level = FactoryBot.create(:level)
        @destroy_later << professor1 = FactoryBot.create(:professor)
        @destroy_later << enrollment = FactoryBot.create(:enrollment, level: level)
        advisement = Advisement.new(professor: professor1, enrollment: enrollment, main_advisor: true)
        expect(advisement).to have(0).errors_on(:base)
      end
    end

    describe "verify_research_area_with_advisors" do
      it "should have error when advisor research area is different from enrollment" do
        @destroy_later << level = FactoryBot.create(:level)
        @destroy_later << research_area1 = FactoryBot.create(:research_area)
        @destroy_later << research_area2 = FactoryBot.create(:research_area)
        @destroy_later << professor1 = FactoryBot.create(:professor)
        @destroy_later << FactoryBot.create(:professor_research_area, professor: professor1, research_area: research_area1)
        @destroy_later << enrollment = FactoryBot.create(:enrollment, level: level, research_area: research_area2)
        @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor1, level: level)
        advisement = Advisement.new(professor: professor1, enrollment: enrollment, main_advisor: true)
        expect(advisement).to have_error(:research_area_different_from_professors).on(:base)
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
        @destroy_later << professor0 = FactoryBot.create(:professor)
        @destroy_later << professor1 = FactoryBot.create(:professor, name: professor1_name)
        @destroy_later << professor2 = FactoryBot.create(:professor, name: professor2_name)
        @destroy_later << level = FactoryBot.create(:level)
        @destroy_later << enrollment = FactoryBot.create(:enrollment, level: level)
        @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor0, level: level)
        @destroy_later << advisement = FactoryBot.create(:advisement, professor: professor0, enrollment: enrollment)
        advisement.enrollment.reload
        @destroy_later << FactoryBot.create(:advisement, professor: professor1, enrollment: advisement.enrollment, main_advisor: false)
        @destroy_later << FactoryBot.create(:advisement, professor: professor2, enrollment: advisement.enrollment, main_advisor: false)
        expect(advisement.co_advisor_list).to eql("#{professor1_name} , #{professor2_name}")
      end
    end
    describe "active" do
      context "should return true when " do
        it "the enrollment does not have a dismissal" do
          @destroy_later << level = FactoryBot.create(:level)
          @destroy_later << professor1 = FactoryBot.create(:professor)
          @destroy_later << enrollment = FactoryBot.create(:enrollment, level: level)
          @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor1, level: level)
          @destroy_later << advisement = FactoryBot.create(:advisement, enrollment: enrollment, professor: professor1)
          expect(advisement.active).to be_truthy
        end
      end
      context "should return false when " do
        it "the enrollment have a dismissal" do
          @destroy_later << level = FactoryBot.create(:level)
          @destroy_later << professor1 = FactoryBot.create(:professor)
          @destroy_later << enrollment = FactoryBot.create(:enrollment, level: level)
          @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor1, level: level)
          @destroy_later << advisement = FactoryBot.create(:advisement, enrollment: enrollment, professor: professor1)
          @destroy_later << FactoryBot.create(:dismissal, enrollment: enrollment)
          expect(advisement.active).to be_falsey
        end
      end
    end
    describe "co_advisor" do
      context "should return true when " do
        it "the enrollment have another advisement" do
          @destroy_later << level = FactoryBot.create(:level)
          @destroy_later << professor1 = FactoryBot.create(:professor)
          @destroy_later << enrollment = FactoryBot.create(:enrollment, level: level)
          @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor1, level: level)
          @destroy_later << other_advisement = FactoryBot.create(:advisement, professor: professor1, enrollment: enrollment)
          other_advisement.enrollment.reload
          @destroy_later << FactoryBot.create(:advisement, enrollment: other_advisement.enrollment, main_advisor: false)
          expect(other_advisement.co_advisor).to be_truthy
        end
      end
      context "should return false when " do
        it "the enrollment does not have another advisement" do
          @destroy_later << level = FactoryBot.create(:level)
          @destroy_later << professor1 = FactoryBot.create(:professor)
          @destroy_later << enrollment = FactoryBot.create(:enrollment, level: level)
          @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor1, level: level)
          @destroy_later << advisement = FactoryBot.create(:advisement, professor: professor1, enrollment: enrollment, main_advisor: true)
          expect(advisement.co_advisor).to be_falsey
        end
      end
    end
    describe "enrollment_has_advisors" do
      context "should return true when " do
        it "the enrollment have one advisement" do
          @destroy_later << level = FactoryBot.create(:level)
          @destroy_later << professor1 = FactoryBot.create(:professor)
          @destroy_later << enrollment = FactoryBot.create(:enrollment, level: level)
          @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor1, level: level)
          @destroy_later << advisement = FactoryBot.create(:advisement, professor: professor1, enrollment: enrollment, main_advisor: true)
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
