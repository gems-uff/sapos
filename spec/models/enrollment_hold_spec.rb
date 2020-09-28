# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'spec_helper'

describe EnrollmentHold do
  let(:enrollment_hold) { EnrollmentHold.new }
  describe "Validations" do
    describe "enrollment" do
      context "should be valid when" do
        it "enrollment is not null" do
          enrollment_hold.enrollment = Enrollment.new
          expect(enrollment_hold).to have(0).errors_on :enrollment
        end
      end
      context "should have error blank when" do
        it "enrollment is null" do
          enrollment_hold.enrollment = nil
          expect(enrollment_hold).to have_error(:blank).on :enrollment
        end
      end
    end
    describe "number_of_semesters" do
      context "should be valid when" do
        it "it is greater than 0" do
          enrollment_hold.number_of_semesters = 1
          expect(enrollment_hold).to have(0).errors_on :number_of_semesters
        end
      end
      context "should have error when" do
        it "it is lower than or equal to 0" do
          enrollment_hold.number_of_semesters = 0
          expect(enrollment_hold).to have_error(:greater_than_or_equal_to).with_parameter(:count, 1).on :number_of_semesters
        end

        it "it is blank" do
          enrollment_hold.number_of_semesters = nil
          expect(enrollment_hold).to have_error(:blank).on :number_of_semesters
        end
      end
    end
    describe "year" do
      context "should be valid when" do
        it "it is not null" do
          enrollment_hold.year = 2014
          expect(enrollment_hold).to have(0).errors_on :year
        end
      end
      context "should have error when" do
        it "it is blank" do
          enrollment_hold.year = nil
          expect(enrollment_hold).to have_error(:blank).on :year
        end
      end
    end
    describe "semester" do
      context "should be valid when" do
        it "it is 1" do
          enrollment_hold.semester = 1
          expect(enrollment_hold).to have(0).errors_on :semester
        end
        it "it is 2" do
          enrollment_hold.semester = 2
          expect(enrollment_hold).to have(0).errors_on :semester
        end
      end
      context "should have error when" do
        it "it is blank" do
          enrollment_hold.semester = nil
          expect(enrollment_hold).to have_error(:blank).on :semester
        end
        it "it isnt 1 or 2" do
          enrollment_hold.semester = nil
          expect(enrollment_hold).to have_error(:inclusion).on :semester
        end
      end
    end

    describe "base" do
      context "should have error when" do
        it "year-semester is before enrollment admission date" do
          e = FactoryBot.create(:enrollment)
          enrollment_hold.enrollment = e
          enrollment_hold.year = e.admission_date.year - 1
          enrollment_hold.semester = 1
          expect(enrollment_hold).to have_error(:before_admission_date).on :base
        end

        it "year-semester is before enrollment admission date" do
          d = FactoryBot.create(:dismissal)
          e = d.enrollment
          enrollment_hold.enrollment = e
          enrollment_hold.year = e.admission_date.year
          enrollment_hold.semester = 1
          enrollment_hold.number_of_semesters = 20
          expect(enrollment_hold).to have_error(:after_dismissal_date).on :base
        end
      end
    end
  end

  describe "Methods" do
    context "to_label" do
      it "should return the semester and the number of semesters" do
        enrollment_hold.year = 2014
        enrollment_hold.semester = 1
        enrollment_hold.number_of_semesters = 2

        expect(enrollment_hold.to_label).to eq("2014.1 - 2 semestres")
      end
    end
  end

end
