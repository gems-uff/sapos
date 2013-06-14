# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Course do
  let(:course) { Course.new }
  subject { course }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          course.name = "Course"
          course.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          course.name = nil
          course.should have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "Course"
          FactoryGirl.create(:course, :name => name)
          course.name = name
          course.should have_error(:taken).on :name
        end
      end
    end
    describe "course_type" do
      context "should be valid when" do
        it "course_type is not null" do
          course.course_type = CourseType.new
          course.should have(0).errors_on :course_type
        end
      end
      context "should have error blank when" do
        it "course_type is null" do
          course.course_type = nil
          course.should have_error(:blank).on :course_type
        end
      end
    end
    describe "code" do
      context "should be valid when" do
        it "code is not null and is not taken" do
          course.code = "Code"
          course.should have(0).errors_on :code
        end
      end
      context "should have error blank when" do
        it "code is null" do
          course.code = nil
          course.should have_error(:blank).on :code
        end
      end
      context "should have error taken when" do
        it "code is already in use" do
          code = "Code"
          FactoryGirl.create(:course, :code => code)
          course.code = code
          course.should have_error(:taken).on :code
        end
      end
    end
    describe "credits" do
      context "should be valid when" do
        it "credits is not null" do
          course.credits = 10
          course.should have(0).errors_on :credits
        end
      end
      context "should have error blank when" do
        it "credits is null" do
          course.credits = nil
          course.should have_error(:blank).on :credits
        end
      end
    end
  end
end