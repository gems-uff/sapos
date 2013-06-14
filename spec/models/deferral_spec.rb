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
  end
end