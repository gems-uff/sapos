# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe DeferralType, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:deferrals).dependent(:restrict_with_exception) }

  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end

  let(:phase) { FactoryBot.build(:phase) }
  let(:deferral_type) do
    DeferralType.new(
      phase: phase,
      name: "prorrogacao",
      duration_semesters: 0,
      duration_months: 0,
      duration_days: 1
    )
  end
  subject { deferral_type }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:phase).required(true) }
    it { should validate_presence_of(:name) }

    describe "duration" do
      context "should have error blank_duration when" do
        it "equals 0" do
          deferral_type.duration_days = 0
          deferral_type.duration_months = 0
          deferral_type.duration_semesters = nil
          expect(deferral_type).to have_error(:blank_duration).on :duration
        end
      end
    end
  end

  describe "Class methods" do
    describe "find_all_for_enrollment" do
      it "should return all deferral_types if enrollment is nil" do
        @destroy_later << FactoryBot.create(:deferral_type)
        @destroy_later << FactoryBot.create(:deferral_type)
        @destroy_later << FactoryBot.create(:deferral_type)

        deferral_types = DeferralType.where(DeferralType.find_all_for_enrollment(nil))
        expect(deferral_types.count).to eq(DeferralType.count)
      end

      it "should return deferral_types that have the same level as the enrollment" do
        @destroy_later << level1 = FactoryBot.create(:level)
        @destroy_later << level2 = FactoryBot.create(:level)

        @destroy_later << phase1 = FactoryBot.create(:phase)
        @destroy_later << FactoryBot.create(:phase_duration, phase: phase1, level: level1)
        @destroy_later << FactoryBot.create(:deferral_type, phase: phase1)

        @destroy_later << phase2 = FactoryBot.create(:phase)
        @destroy_later << FactoryBot.create(:phase_duration, phase: phase2, level: level1)
        @destroy_later << FactoryBot.create(:deferral_type, phase: phase2)

        @destroy_later << phase3 = FactoryBot.create(:phase)
        @destroy_later << FactoryBot.create(:phase_duration, phase: phase3, level: level2)
        @destroy_later << FactoryBot.create(:deferral_type, phase: phase3)

        @destroy_later << enrollment = FactoryBot.create(:enrollment, level: level1)

        deferral_types = DeferralType.where(DeferralType.find_all_for_enrollment(enrollment))
        expect(deferral_types.count).to eq(2)
      end

      it "should not return an deferral_type, whose phase is inactive, if enrollment is nil" do
        @destroy_later << phase1 = FactoryBot.create(:phase, active: false)
        @destroy_later << FactoryBot.create(:deferral_type, phase: phase1)
        deferral_types = DeferralType.where(DeferralType.find_all_for_enrollment(nil))
        expect(deferral_types.count).to eq(0)
      end

      it "should not return an deferral_type, whose phase is inactive, that have the same level as the enrollment" do
        @destroy_later << level1 = FactoryBot.create(:level)

        @destroy_later << phase1 = FactoryBot.create(:phase, active: false)
        @destroy_later << FactoryBot.create(:phase_duration, phase: phase1, level: level1)
        @destroy_later << FactoryBot.create(:deferral_type, phase: phase1)

        @destroy_later << enrollment = FactoryBot.create(:enrollment, level: level1)

        deferral_types = DeferralType.where(DeferralType.find_all_for_enrollment(enrollment))
        expect(deferral_types.count).to eq(0)
      end
    end
  end
end
