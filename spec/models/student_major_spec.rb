require 'spec_helper'

describe StudentMajor do
  let(:student_major) { StudentMajor.new }
  subject { student_major }
  describe "Validations" do
    describe "student" do
      context "should be valid when" do
        it "student is not null" do
          student_major.student = Student.new
          student_major.should have(0).errors_on :student
        end
      end
      context "should have error blank when" do
        it "student is null" do
          student_major.student = nil
          student_major.should have_error(:blank).on :student
        end
      end
    end
    describe "major" do
      context "should be valid when" do
        it "major is not null" do
          student_major.major = Major.new
          student_major.should have(0).errors_on :major
        end
      end
      context "should have error blank when" do
        it "major is null" do
          student_major.major = nil
          student_major.should have_error(:blank).on :major
        end
      end
    end

    describe "student_id" do
      context "should be valid when" do
        it "don't exists the same student for the same major" do
          student_major.student = Student.new
          student_major.should have(0).errors_on :student_id
        end
      end
      context "should have uniqueness error when" do
        it "already exists the same student for the same major" do
          student_major.student = FactoryGirl.create(:student)
          student_major.major = FactoryGirl.create(:major)
          FactoryGirl.create(:student_major, :student => student_major.student, :major => student_major.major)
          student_major.should have_error(:unique_pair).on :student_id
        end
      end
    end
  end
end
