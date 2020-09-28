# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'spec_helper'

describe StudentMajor do
  let(:student_major) { StudentMajor.new }
  subject { student_major }
  describe "Validations" do
    describe "student" do
      context "should be valid when" do
        it "student is not null" do
          student_major.student = Student.new
          expect(student_major).to have(0).errors_on :student
        end
      end
      context "should have error blank when" do
        it "student is null" do
          student_major.student = nil
          expect(student_major).to have_error(:blank).on :student
        end
      end
    end
    describe "major" do
      context "should be valid when" do
        it "major is not null" do
          student_major.major = Major.new
          expect(student_major).to have(0).errors_on :major
        end
      end
      context "should have error blank when" do
        it "major is null" do
          student_major.major = nil
          expect(student_major).to have_error(:blank).on :major
        end
      end
    end

    describe "student_id" do
      context "should be valid when" do
        it "don't exists the same student for the same major" do
          student_major.student = Student.new
          expect(student_major).to have(0).errors_on :student_id
        end
      end
      context "should have uniqueness error when" do
        it "already exists the same student for the same major" do
          student_major.student = FactoryBot.create(:student)
          student_major.major = FactoryBot.create(:major)
          FactoryBot.create(:student_major, :student => student_major.student, :major => student_major.major)
          expect(student_major).to have_error(:unique_pair).on :student_id
        end
      end
    end
  end
end
