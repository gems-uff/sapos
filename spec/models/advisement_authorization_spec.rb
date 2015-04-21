# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe AdvisementAuthorization do
  let(:advisement_authorization) { AdvisementAuthorization.new }
  subject { advisement_authorization }
  describe "Validations" do
    describe "professor" do
      context "should be valid when" do
        it "professor is not null" do
          advisement_authorization.professor = Professor.new
          advisement_authorization.should have(0).errors_on :professor
        end
      end
      context "should have error blank when" do
        it "professor is null" do
          advisement_authorization.professor = nil
          advisement_authorization.should have_error(:blank).on :professor
        end
      end
    end
    describe "level" do
      context "should be valid when" do
        it "level is not null" do
          advisement_authorization.level = Level.new
          advisement_authorization.should have(0).errors_on :level
        end
      end
      context "should have error blank when" do
        it "level is null" do
          advisement_authorization.level = nil
          advisement_authorization.should have_error(:blank).on :level
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        level_name = "AuthorizedLevel"
        advisement_authorization.level = Level.new(:name => level_name)
        advisement_authorization.to_label.should eql(level_name)
      end
    end
  end
end