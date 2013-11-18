# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe EnrollmentStatus do
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists :enrollment }

  let(:enrollment_status) { EnrollmentStatus.new }
  subject { enrollment_status }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          enrollment_status.name = "EnrollmentStatus name"
          enrollment_status.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          enrollment_status.name = nil
          enrollment_status.should have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "EnrollmentStatus name"
          FactoryGirl.create(:enrollment_status, :name => name)
          enrollment_status.name = name
          enrollment_status.should have_error(:taken).on :name
        end
      end
    end
  end
end