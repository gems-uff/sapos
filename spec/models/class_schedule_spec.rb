require 'spec_helper'

RSpec.describe ClassSchedule, type: :model do
  let(:class_schedule) { ClassSchedule.new }
  subject { class_schedule }
  describe "Validations" do
    describe "year" do
      context "should be valid when" do
        it "year is not null" do
          class_schedule.year = 2021
          expect(class_schedule).to have(0).errors_on :year
        end
      end
      context "should have error blank when" do
        it "year is null" do
          class_schedule.year = nil
          expect(class_schedule).to have_error(:blank).on :year
        end
      end
    end
    describe "semester" do
      context "should be valid when" do
        it "semester is in Semesters list" do
          class_schedule.semester = YearSemester::SEMESTERS[0]
          expect(class_schedule).to have(0).errors_on :semester
        end
      end
      context "should have error blank when" do
        it "semester is null" do
          class_schedule.semester = nil
          expect(class_schedule).to have_error(:blank).on :semester
        end
      end
      context "should have error inclusion when" do
        it "semester is not in the list" do
          class_schedule.semester = 10
          expect(class_schedule).to have_error(:inclusion).on :semester
        end
      end
      context "should have error taken when" do
        it "semester already exists for the same year" do
          FactoryBot.create(:class_schedule, year: 2021, semester: YearSemester::SEMESTERS[0])

          class_schedule.year = 2021
          class_schedule.semester = YearSemester::SEMESTERS[0]
          expect(class_schedule).to have_error(:taken).on :semester
        end
      end
    end
    describe "enrollment_start" do
      context "should be valid when" do
        it "enrollment_start is not null" do
          class_schedule.enrollment_start = Time.now
          expect(class_schedule).to have(0).errors_on :enrollment_start
        end
      end
      context "should have error blank when" do
        it "enrollment_start is null" do
          class_schedule.enrollment_start = nil
          expect(class_schedule).to have_error(:blank).on :enrollment_start
        end
      end
    end
    describe "enrollment_end" do
      context "should be valid when" do
        it "enrollment_end is not null" do
          class_schedule.enrollment_end = Time.now
          expect(class_schedule).to have(0).errors_on :enrollment_end
        end
      end
      context "should have error blank when" do
        it "enrollment_end is null" do
          class_schedule.enrollment_end = nil
          expect(class_schedule).to have_error(:blank).on :enrollment_end
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return YYYY.S" do 
        class_schedule.year = 2021
        class_schedule.semester = 1
        expect(class_schedule.to_label).to eq("2021.1")
      end
    end
    describe "enroll_open?" do
      it "should return true when time is in between the start and end dates" do
        now = Time.now
        class_schedule.enrollment_start = now - 1.day
        class_schedule.enrollment_end = now + 1.day
        expect(class_schedule.enroll_open?).to eq(true)
        expect(class_schedule.enroll_open?(now)).to eq(true)
      end
      it "should return false when time before the start date" do
        now = Time.now
        class_schedule.enrollment_start = now + 1.day
        class_schedule.enrollment_end = now + 2.days
        expect(class_schedule.enroll_open?).to eq(false)
        expect(class_schedule.enroll_open?(now - 3.days)).to eq(false)
      end
      it "should return false when time after the end date" do
        now = Time.now
        class_schedule.enrollment_start = now + 1.day
        class_schedule.enrollment_end = now + 2.days
        expect(class_schedule.enroll_open?(now + 3.days)).to eq(false)
      end
    end
  end
end
