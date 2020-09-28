# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Course do
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists :course_class }

  let(:course) { Course.new }
  subject { course }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          course.name = "Course"
          expect(course).to have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          course.name = nil
          expect(course).to have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
	it "name of available course is already in use" do
          name = "Course"
	  FactoryBot.create(:course, :name => name, :available => true)
	  course.name = name
	  expect(course).to have_error(:check_unique_name_for_available_courses).on :name
	end
      end
    end
    describe "course_type" do
      context "should be valid when" do
        it "course_type is not null" do
          course.course_type = CourseType.new
          expect(course).to have(0).errors_on :course_type
        end
      end
      context "should have error blank when" do
        it "course_type is null" do
          course.course_type = nil
          expect(course).to have_error(:blank).on :course_type
        end
      end
    end
    describe "code" do
      context "should be valid when" do
        it "code is not null and is not taken" do
          course.code = "Code"
          expect(course).to have(0).errors_on :code
        end
      end
      context "should have error blank when" do
        it "code is null" do
          course.code = nil
          expect(course).to have_error(:blank).on :code
        end
      end
      context "should have error taken when" do
        it "code is already in use" do
          code = "Code"
          FactoryBot.create(:course, :code => code)
          course.code = code
          expect(course).to have_error(:taken).on :code
        end
      end
    end
    describe "credits" do
      context "should be valid when" do
        it "credits is not null" do
          course.credits = 10
          expect(course).to have(0).errors_on :credits
        end
      end
      context "should have error blank when" do
        it "credits is null" do
          course.credits = nil
          expect(course).to have_error(:blank).on :credits
        end
      end
    end
    describe "workload" do
      context "should be valid when" do
        it "workload is not null" do
          course.workload = 10
          expect(course).to have(0).errors_on :workload
        end
      end
      context "should have error blank when" do
        it "workload is null" do
          course.workload = nil
          expect(course).to have_error(:blank).on :workload
        end
      end
    end
  end
  describe "Methods" do
    context "workload_value" do
      it "should return 0 when there is no workload" do
        course.workload = nil
        expect(course.workload_value).to eq(0)
      end

      it "should return 5 when workload is 5" do
        course.workload = 5
        expect(course.workload_value).to eq(5)
      end
    end

    context "workload_text" do
      it "should return N/A when there is no workload" do
        course.workload = nil
        expect(course.workload_text).to eq(I18n.translate('activerecord.attributes.course.empty_workload'))
      end

      it "should return 5h when workload is 5" do
        course.workload = 5
        expect(course.workload_text).to eq(I18n.translate('activerecord.attributes.course.workload_time', :time => 5))
      end
    end

  end
end
