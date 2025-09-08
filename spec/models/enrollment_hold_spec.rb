# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.configure do |c|
  c.include DateHelpers
end

RSpec.describe EnrollmentHold, type: :model do
  it { should be_able_to_be_destroyed }

  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end

  let(:enrollment) { 
    enrollment = FactoryBot.build(:enrollment, admission_date: YearSemester.current.semester_begin - 2.years)
  }
  let(:enrollment_hold) do
    EnrollmentHold.new(
      enrollment: enrollment,
      semester: YearSemester.current.semester,
      year: YearSemester.current.year,
      number_of_semesters: 1
    )
  end
  subject { enrollment_hold }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:enrollment).required(true) }
    it { should validate_presence_of(:year) }
    it { should validate_inclusion_of(:semester).in_array([1, 2]) }
    it { should validate_presence_of(:semester) }
    it { should validate_numericality_of(:number_of_semesters).is_greater_than_or_equal_to(1) }
    it { should validate_presence_of(:number_of_semesters) }

    describe "base" do
      context "should have error when" do
        it "year-semester is before enrollment admission date" do
          @destroy_later << e = FactoryBot.create(:enrollment)
          enrollment_hold.enrollment = e
          enrollment_hold.year = e.admission_date.year - 1
          enrollment_hold.semester = 1
          expect(enrollment_hold).to have_error(:before_admission_date).on :base
        end

        it "year-semester is before enrollment admission date" do
          @destroy_later << d = FactoryBot.create(:dismissal)
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
