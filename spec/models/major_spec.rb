# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Major do
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists :student_major }

  let(:major) { Major.new }
  subject { major }
  describe "Validations" do
    describe "institution" do
      context "should be valid when" do
        it "institution is not null" do
          major.institution = Institution.new
          major.should have(0).errors_on :institution
        end
      end
      context "should have error blank when" do
        it "institution is null" do
          major.institution = nil
          major.should have_error(:blank).on :institution
        end
      end
    end
    describe "level" do
      context "should be valid when" do
        it "level is not null" do
          major.level = Level.new
          major.should have(0).errors_on :level
        end
      end
      context "should have error blank when" do
        it "level is null" do
          major.level = nil
          major.should have_error(:blank).on :level
        end
      end
    end
    describe "name" do
      context "should be valid when" do
        it "name is not null" do
          major.name = "Name"
          major.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          major.name = nil
          major.should have_error(:blank).on :name
        end
      end
    end
  end

  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        level_name = "Major Level"
        major_name = "Major Name"
        institution_name = "Major Institution"
        major.level = Level.new(:name => level_name)
        major.name = major_name
        major.institution = Institution.new(:name => institution_name)
        expected = "#{major_name} - #{institution_name} - (#{level_name})"
        major.to_label.should eql(expected)
      end
    end
  end
end