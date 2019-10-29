# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Deferral do
  let(:deferral) { Deferral.new }
  subject { deferral }
  describe "Validations" do
    describe "enrollment" do
      context "should be valid when" do
        it "enrollment is not null" do
          deferral.enrollment = Enrollment.new
          expect(deferral).to have(0).errors_on :enrollment
        end

        it "deferral_type phase has the enrollment level" do
          level = FactoryGirl.create(:level)
          phase = FactoryGirl.create(:phase)
          deferral.enrollment = FactoryGirl.create(:enrollment, :level => level)
          deferral.deferral_type = FactoryGirl.create(:deferral_type, :phase => phase)
          phase_duration = FactoryGirl.create(:phase_duration, :phase => phase, :level => level)
          
          expect(deferral).to have(0).errors_on :enrollment
        end
      end
      context "should have error blank when" do
        it "enrollment is null" do
          deferral.enrollment = nil
          expect(deferral).to have_error(:blank).on :enrollment
        end
      end

      context "should have error enrollment_level when" do
        it "deferral_type phase doesn't have the enrollment level" do
          level = FactoryGirl.create(:level)
          phase = FactoryGirl.create(:phase)
          deferral.enrollment = FactoryGirl.create(:enrollment, :level => level)
          deferral.deferral_type = FactoryGirl.create(:deferral_type, :phase => phase)
          
          expect(deferral).to have_error(:enrollment_level).on :enrollment
        end
      end
    end
    describe "deferral_type" do
      context "should be valid when" do
        it "deferral_type is not null" do
          deferral.deferral_type = DeferralType.new
          expect(deferral).to have(0).errors_on :deferral_type
        end
      end
      context "should have error blank when" do
        it "deferral_type is null" do
          deferral.deferral_type = nil
          expect(deferral).to have_error(:blank).on :deferral_type
        end
      end
    end
    describe "approval_date" do
      context "should be valid when" do
        it "approval_date is not null" do
          deferral.approval_date = Date.parse("2014/01/01")
          expect(deferral).to have(0).errors_on :approval_date
        end
      end
      context "should have error blank when" do
        it "approval_date is null" do
          deferral.approval_date = nil
          expect(deferral).to have_error(:blank).on :approval_date
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        deferral_type_name = "DeferralType"
        deferral.deferral_type = DeferralType.new(:name => deferral_type_name)
        expect(deferral.to_label).to eql(deferral_type_name)
      end
    end
    describe "valid_until" do
      it "should return 31th of july 2013" do
        phase = FactoryGirl.create(:phase)
        level = FactoryGirl.create(:level)
        enrollment = FactoryGirl.create(:enrollment, :level => level, :admission_date => Date.new(2012, 3, 1))
        phase_duration = FactoryGirl.create(:phase_duration, :phase => phase, :deadline_semesters => 1, :level => level, :deadline_days => 0)
        deferral_type = FactoryGirl.create(:deferral_type, :phase => phase, :duration_semesters => 2, :duration_days => 0)
        deferral = FactoryGirl.create(:deferral, :enrollment => enrollment, :deferral_type => deferral_type, :approval_date => Date.today)

        expect(deferral.valid_until).to eql(Date.new(2013, 7, 31).strftime('%d/%m/%Y'))
      end

      it "should return 28th of february 2023" do
        phase = FactoryGirl.create(:phase)
        level = FactoryGirl.create(:level)
        enrollment = FactoryGirl.create(:enrollment, :level => level, :admission_date => Date.new(2017, 8, 1))
        phase_duration = FactoryGirl.create(:phase_duration, :phase => phase, :deadline_semesters => 8, :level => level, :deadline_days => 0)
        deferral_type = FactoryGirl.create(:deferral_type, :phase => phase, :duration_semesters => 3, :duration_days => 0)
        deferral = FactoryGirl.create(:deferral, :enrollment => enrollment, :deferral_type => deferral_type, :approval_date => Date.today)


        expect(deferral.valid_until).to eql(Date.new(2023, 2, 28).strftime('%d/%m/%Y'))
      end

      it "should return 7th of june 2014" do
        phase = FactoryGirl.create(:phase)
        level = FactoryGirl.create(:level)
        enrollment = FactoryGirl.create(:enrollment, :level => level, :admission_date => Date.new(2013, 8, 1))
        phase_duration = FactoryGirl.create(:phase_duration, :phase => phase, :deadline_semesters => 1, :level => level, :deadline_days => 0)
        deferral_type = FactoryGirl.create(:deferral_type, :phase => phase, :duration_months => 3, :duration_days => 7)
        deferral = FactoryGirl.create(:deferral, :enrollment => enrollment, :deferral_type => deferral_type, :approval_date => Date.today)

        expect(deferral.valid_until).to eql(Date.new(2014, 6, 7).strftime('%d/%m/%Y'))
      end
    end
  end
end
