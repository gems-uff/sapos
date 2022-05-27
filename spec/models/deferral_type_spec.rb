# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe DeferralType do
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists :deferral }

  let(:deferral_type) { DeferralType.new }
  subject { deferral_type }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null" do
          deferral_type.name = "DeferralType"
          expect(deferral_type).to have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          deferral_type.name = nil
          expect(deferral_type).to have_error(:blank).on :name
        end
      end
    end
    describe "phase" do
      context "should be valid when" do
        it "phase is not null" do
          deferral_type.phase = Phase.new
          expect(deferral_type).to have(0).errors_on :phase
        end
      end
      context "should have error blank when" do
        it "phase is null" do
          deferral_type.phase = nil
          expect(deferral_type).to have_error(:blank).on :phase
        end
      end
    end
    describe "duration" do
      context "should be valid when" do
        it "is equal or greater than one day" do
          deferral_type.duration_months = 0
          deferral_type.duration_semesters = 0
          deferral_type.duration_days = 1
          expect(deferral_type).to have(0).errors_on :duration
        end
      end
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
        FactoryBot.create(:deferral_type)
        FactoryBot.create(:deferral_type)
        FactoryBot.create(:deferral_type)
        
        deferral_types = DeferralType.where(DeferralType::find_all_for_enrollment(nil))
        expect(deferral_types.count).to eq(DeferralType.count)
      end

      it "should return deferral_types that have the same level as the enrollment" do
        Deferral.destroy_all
        DeferralType.destroy_all
        level1 = FactoryBot.create(:level)
        level2 = FactoryBot.create(:level)
        
        phase1 = FactoryBot.create(:phase)
        FactoryBot.create(:phase_duration, :phase => phase1, :level => level1)
        FactoryBot.create(:deferral_type, :phase => phase1)

        phase2 = FactoryBot.create(:phase)
        FactoryBot.create(:phase_duration, :phase => phase2, :level => level1)
        FactoryBot.create(:deferral_type, :phase => phase2)
          
        phase3 = FactoryBot.create(:phase)
        FactoryBot.create(:phase_duration, :phase => phase3, :level => level2)
        FactoryBot.create(:deferral_type, :phase => phase3)

        enrollment = FactoryBot.create(:enrollment, :level => level1) 
        
        deferral_types = DeferralType.where(DeferralType::find_all_for_enrollment(enrollment))
        expect(deferral_types.count).to eq(2)
      end

      it "should not return an deferral_type, whose phase is inactive, if enrollment is nil" do
        Deferral.destroy_all
        DeferralType.destroy_all
        phase1 = FactoryBot.create(:phase, :active => false)
        FactoryBot.create(:deferral_type, :phase => phase1)
        deferral_types = DeferralType.where(DeferralType::find_all_for_enrollment(nil))
        expect(deferral_types.count).to eq(0)
      end

      it "should not return an deferral_type, whose phase is inactive, that have the same level as the enrollment" do
        Deferral.destroy_all
        DeferralType.destroy_all
        level1 = FactoryBot.create(:level)

        phase1 = FactoryBot.create(:phase, :active => false)
        FactoryBot.create(:phase_duration, :phase => phase1, :level => level1)
        FactoryBot.create(:deferral_type, :phase => phase1)

        enrollment = FactoryBot.create(:enrollment, :level => level1)

        deferral_types = DeferralType.where(DeferralType::find_all_for_enrollment(enrollment))
        expect(deferral_types.count).to eq(0)
      end

    end
  end
end
