# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe CourseType do
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists :course }
  
  let(:course_type) { CourseType.new }
  subject { course_type }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          course_type.name = "CourseType name"
          course_type.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          course_type.name = nil
          course_type.should have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "CourseType name"
          FactoryGirl.create(:course_type, :name => name)
          course_type.name = name
          course_type.should have_error(:taken).on :name
        end
      end
    end
  end
end