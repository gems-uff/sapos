# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
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
          deferral.should have(0).errors_on :enrollment
        end
      end
      context "should have error blank when" do
        it "enrollment is null" do
          deferral.enrollment = nil
          deferral.should have_error(:blank).on :enrollment
        end
      end
    end
    describe "deferral_type" do
      context "should be valid when" do
        it "deferral_type is not null" do
          deferral.deferral_type = DeferralType.new
          deferral.should have(0).errors_on :deferral_type
        end
      end
      context "should have error blank when" do
        it "deferral_type is null" do
          deferral.deferral_type = nil
          deferral.should have_error(:blank).on :deferral_type
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        deferral_type_name = "DeferralType"
        deferral.deferral_type = DeferralType.new(:name => deferral_type_name)
        deferral.to_label.should eql(deferral_type_name)
      end
    end
    describe "valid_until" do
      it "should return 31th of july 2013" do
        phase = FactoryGirl.create(:phase)
        level = FactoryGirl.create(:level)
        enrollment = FactoryGirl.create(:enrollment, :level => level, :admission_date => Date.new(2012, 3, 1))
        FactoryGirl.create(:accomplishment, :phase => phase, :enrollment => enrollment)
        phase_duration = FactoryGirl.create(:phase_duration, :phase => phase, :deadline_semesters => 1, :level => level, :deadline_days => 0)
        deferral_type = FactoryGirl.create(:deferral_type, :phase => phase, :duration_semesters => 2, :duration_days => 0)
        deferral = FactoryGirl.create(:deferral, :enrollment => enrollment, :deferral_type => deferral_type, :approval_date => Date.today)

        deferral.valid_until.should eql(Date.new(2013, 7, 31).strftime('%d/%m/%Y'))
      end

      it "should return 28th of february 2023" do
        phase = FactoryGirl.create(:phase)
        level = FactoryGirl.create(:level)
        enrollment = FactoryGirl.create(:enrollment, :level => level, :admission_date => Date.new(2017, 8, 1))
        FactoryGirl.create(:accomplishment, :phase => phase, :enrollment => enrollment)
        phase_duration = FactoryGirl.create(:phase_duration, :phase => phase, :deadline_semesters => 8, :level => level, :deadline_days => 0)
        deferral_type = FactoryGirl.create(:deferral_type, :phase => phase, :duration_semesters => 3, :duration_days => 0)
        deferral = FactoryGirl.create(:deferral, :enrollment => enrollment, :deferral_type => deferral_type, :approval_date => Date.today)


        deferral.valid_until.should eql(Date.new(2023, 2, 28).strftime('%d/%m/%Y'))
      end

      it "should return 7th of june 2014" do
        phase = FactoryGirl.create(:phase)
        level = FactoryGirl.create(:level)
        enrollment = FactoryGirl.create(:enrollment, :level => level, :admission_date => Date.new(2013, 8, 1))
        FactoryGirl.create(:accomplishment, :phase => phase, :enrollment => enrollment)
        phase_duration = FactoryGirl.create(:phase_duration, :phase => phase, :deadline_semesters => 1, :level => level, :deadline_days => 0)
        deferral_type = FactoryGirl.create(:deferral_type, :phase => phase, :duration_months => 3, :duration_days => 7)
        deferral = FactoryGirl.create(:deferral, :enrollment => enrollment, :deferral_type => deferral_type, :approval_date => Date.today)

        deferral.valid_until.should eql(Date.new(2014, 6, 7).strftime('%d/%m/%Y'))
      end
    end
  end
end