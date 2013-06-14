# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe DeferralType do
  let(:deferral_type) { DeferralType.new }
  subject { deferral_type }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null" do
          deferral_type.name = "DeferralType"
          deferral_type.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          deferral_type.name = nil
          deferral_type.should have_error(:blank).on :name
        end
      end
    end
    describe "phase" do
      context "should be valid when" do
        it "phase is not null" do
          deferral_type.phase = Phase.new
          deferral_type.should have(0).errors_on :phase
        end
      end
      context "should have error blank when" do
        it "phase is null" do
          deferral_type.phase = nil
          deferral_type.should have_error(:blank).on :phase
        end
      end
    end
    describe "duration" do
      context "should be valid when" do
        it "is equal or greater than one day" do
          deferral_type.duration_months = 0
          deferral_type.duration_semesters = 0
          deferral_type.duration_days = 1
          deferral_type.should have(0).errors_on :duration
        end
      end
      context "should have error blank_duration when" do
        it "equals 0" do
          deferral_type.duration_days = 0
          deferral_type.duration_months = 0
          deferral_type.duration_semesters = nil
          deferral_type.should have_error(:blank_duration).on :duration
        end
      end
    end
  end
end