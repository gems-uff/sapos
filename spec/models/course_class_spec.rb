require "spec_helper"

describe CourseClass do
  let(:course_class) { CourseClass.new }
  subject { course_class }
  describe "Validations" do
    describe "course" do
      context "should be valid when" do
        it "course is not null" do
          course_class.course = Course.new
          course_class.should have(0).errors_on :course
        end
      end
      context "should have error blank when" do
        it "course is null" do
          course_class.course = nil
          course_class.should have_error(:blank).on :course
        end
      end
    end
    describe "professor" do
      context "should be valid when" do
        it "professor is not null" do
          course_class.professor = Professor.new
          course_class.should have(0).errors_on :professor
        end
      end
      context "should have error blank when" do
        it "professor is null" do
          course_class.professor = nil
          course_class.should have_error(:blank).on :professor
        end
      end
    end
    describe "year" do
      context "should be valid when" do
        it "year is not null" do
          course_class.year = 2013
          course_class.should have(0).errors_on :year
        end
      end
      context "should have error blank when" do
        it "year is null" do
          course_class.year = nil
          course_class.should have_error(:blank).on :year
        end
      end
    end
    describe "semester" do
      context "should be valid when" do
        it "semester is not null" do
          course_class.semester = CourseClass::SEMESTERS.first
          course_class.should have(0).errors_on :semester
        end
      end
      context "should have error blank when" do
        it "semester is null" do
          course_class.semester = nil
          course_class.should have_error(:blank).on :semester
        end
      end
      context "should have error inclusion when" do
        it "semester is not in the list" do
          course_class.semester = 3
          course_class.should have_error(:inclusion).on :semester
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      context "should return the expected string when" do
        it "name is not null" do
          name = "name"
          course_class.name = name
          course_class.year = 2013
          course_class.semester = CourseClass::SEMESTERS.first
          course_class.course = Course.new(:name => "Other name")
          course_class.to_label.should eql("#{name} - #{course_class.year}/#{course_class.semester}")
        end
        it "name is null" do
          course_name = "course_name"
          course_class.year = 2013
          course_class.semester = CourseClass::SEMESTERS.first
          course_class.course = Course.new(:name => course_name)
          course_class.to_label.should eql("#{course_name} - #{course_class.year}/#{course_class.semester}")
        end
      end
    end
  end
end