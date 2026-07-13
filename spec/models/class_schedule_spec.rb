# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe ClassSchedule, type: :model do
  it { should be_able_to_be_destroyed }

  let(:class_schedule) do
    ClassSchedule.new(
      year: 2023,
      semester: 2,
      enrollment_start: Time.now,
      enrollment_end: Time.now,
      period_start: Time.now,
      enrollment_insert: Time.now,
      enrollment_remove: Time.now,
      period_end: Time.now,
      grades_deadline: Time.now
    )
  end
  subject { class_schedule }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:year) }
    it { should validate_inclusion_of(:semester).in_array(YearSemester::SEMESTERS) }
    it { should validate_uniqueness_of(:semester).scoped_to(:year) }
    it { should validate_presence_of(:semester) }
    it { should validate_presence_of(:enrollment_start) }
    it { should validate_presence_of(:enrollment_end) }
    it { should validate_presence_of(:period_start) }
    it { should validate_presence_of(:enrollment_insert) }
    it { should validate_presence_of(:enrollment_remove) }
    it { should validate_presence_of(:period_end) }
    it { should validate_presence_of(:grades_deadline) }
  end
  before(:all) do
      now = Time.now
      @open_main = FactoryBot.create(:class_schedule,
        year: 9990, semester: 1,
        enrollment_start: now - 1.day, enrollment_end: now + 1.day,
        period_start: now + 3.days, enrollment_insert: now + 4.days,
        enrollment_remove: now + 4.days, period_end: now + 5.days,
        grades_deadline: now + 6.days
      )
      @open_insert = FactoryBot.create(:class_schedule,
        year: 9990, semester: 2,
        enrollment_start: now - 5.days, enrollment_end: now - 4.days,
        period_start: now - 1.day, enrollment_insert: now + 1.day,
        enrollment_remove: now - 1.day, period_end: now + 2.days,
        grades_deadline: now + 3.days
      )
      @open_remove = FactoryBot.create(:class_schedule,
        year: 9991, semester: 1,
        enrollment_start: now - 5.days, enrollment_end: now - 4.days,
        period_start: now - 1.day, enrollment_insert: now - 1.day,
        enrollment_remove: now + 1.day, period_end: now + 2.days,
        grades_deadline: now + 3.days
      )
      @closed = FactoryBot.create(:class_schedule,
        year: 9992, semester: 1,
        enrollment_start: now + 1.day, enrollment_end: now + 2.days,
        period_start: now + 3.days, enrollment_insert: now + 4.days,
        enrollment_remove: now + 4.days, period_end: now + 5.days,
        grades_deadline: now + 6.days
      )
    end
    after(:all) do
      @closed.delete
      @open_remove.delete
      @open_insert.delete
      @open_main.delete
    end
  describe "Methods" do
    describe "to_label" do
      it "should return YYYY.S" do
        class_schedule.year = 2021
        class_schedule.semester = 1
        expect(class_schedule.to_label).to eq("2021.1")
      end
    end
    describe "main_enroll_open?" do
      it "should return true when time is in between the start and end dates" do
        now = Time.now
        class_schedule.enrollment_start = now - 1.day
        class_schedule.enrollment_end = now + 1.day
        expect(class_schedule.main_enroll_open?).to eq(true)
        expect(class_schedule.main_enroll_open?(now)).to eq(true)
      end
      it "should return false when time before the start date" do
        now = Time.now
        class_schedule.enrollment_start = now + 1.day
        class_schedule.enrollment_end = now + 2.days
        expect(class_schedule.main_enroll_open?).to eq(false)
        expect(class_schedule.main_enroll_open?(now - 3.days)).to eq(false)
      end
      it "should return false when time after the end date" do
        now = Time.now
        class_schedule.enrollment_start = now + 1.day
        class_schedule.enrollment_end = now + 2.days
        expect(class_schedule.main_enroll_open?(now + 3.days)).to eq(false)
      end
    end
    describe "adjust_enroll_insert_open?" do
      it "should return true when time is in between the adjust and insert dates" do
        now = Time.now
        class_schedule.period_start = now - 1.day
        class_schedule.enrollment_insert = now + 1.day
        expect(class_schedule.adjust_enroll_insert_open?).to eq(true)
        expect(class_schedule.adjust_enroll_insert_open?(now)).to eq(true)
      end
      it "should return false when time before the adjust date" do
        now = Time.now
        class_schedule.period_start = now + 1.day
        class_schedule.enrollment_insert = now + 2.days
        expect(class_schedule.adjust_enroll_insert_open?).to eq(false)
        expect(class_schedule.adjust_enroll_insert_open?(now - 3.days)).to eq(false)
      end
      it "should return false when time after both the insert and remove dates" do
        now = Time.now
        class_schedule.period_start = now + 1.day
        class_schedule.enrollment_insert = now + 2.days
        expect(class_schedule.adjust_enroll_insert_open?(now + 3.days)).to eq(false)
      end
    end
    describe "adjust_enroll_remove_open?" do
      it "should return true when time is in between the adjust and remove dates" do
        now = Time.now
        class_schedule.period_start = now - 1.day
        class_schedule.enrollment_remove = now + 1.day
        expect(class_schedule.adjust_enroll_remove_open?).to eq(true)
        expect(class_schedule.adjust_enroll_remove_open?(now)).to eq(true)
      end
      it "should return false when time before the adjust date" do
        now = Time.now
        class_schedule.period_start = now + 1.day
        class_schedule.enrollment_remove = now + 2.days
        expect(class_schedule.adjust_enroll_remove_open?).to eq(false)
        expect(class_schedule.adjust_enroll_remove_open?(now - 3.days)).to eq(false)
      end
      it "should return false when time after both the insert and remove dates" do
        now = Time.now
        class_schedule.period_start = now + 1.day
        class_schedule.enrollment_remove = now + 2.days
        expect(class_schedule.adjust_enroll_remove_open?(now + 3.days)).to eq(false)
      end
    end
    describe "show period end?" do
      it "should return true when period_end minus 7 days is on or before now" do
        now = Time.now
        class_schedule.period_end = now - 1.day
        expect(class_schedule.show_period_end?(now)).to eq(true)
      end

      it "should return true when period_end minus 7 days equals now" do
        now = Time.now
        class_schedule.period_end = now + 7.days
        expect(class_schedule.show_period_end?(now)).to eq(true)
      end

      it "should return false when period_end is more than 7 days from now" do
        now = Time.now
        class_schedule.period_end = now + 8.days
        expect(class_schedule.show_period_end?(now)).to eq(false)
      end
    end

    describe "grades deadline to view" do
      it "should return formatted DD/MM string" do
        class_schedule.grades_deadline = Date.new(2023, 3, 5)
        expect(class_schedule.grades_deadline_to_view).to eq("05/03")
      end
    end

    describe "open for removing class enrollments?" do
      it "should return true when main enrollment is open" do
        now = Time.now
        class_schedule.enrollment_start = now - 1.day
        class_schedule.enrollment_end = now + 1.day
        class_schedule.period_start = now + 5.days
        class_schedule.enrollment_remove = now + 6.days
        expect(class_schedule.open_for_removing_class_enrollments?).to eq(true)
        expect(class_schedule.open_for_removing_class_enrollments?(now)).to eq(true)
      end

      it "should return true when adjust enroll remove is open" do
        now = Time.now
        class_schedule.enrollment_start = now - 5.days
        class_schedule.enrollment_end = now - 4.days
        class_schedule.period_start = now - 1.day
        class_schedule.enrollment_remove = now + 1.day
        expect(class_schedule.open_for_removing_class_enrollments?).to eq(true)
        expect(class_schedule.open_for_removing_class_enrollments?(now)).to eq(true)
      end

      it "should return false when neither main nor remove is open" do
        now = Time.now
        class_schedule.enrollment_start = now - 5.days
        class_schedule.enrollment_end = now - 4.days
        class_schedule.period_start = now + 1.day
        class_schedule.enrollment_remove = now + 2.days
        expect(class_schedule.open_for_removing_class_enrollments?).to eq(false)
        expect(class_schedule.open_for_removing_class_enrollments?(now)).to eq(false)
      end
    end

    describe "open for inserting class enrollments?" do
      it "should return true when main enrollment is open" do
        now = Time.now
        class_schedule.enrollment_start = now - 1.day
        class_schedule.enrollment_end = now + 1.day
        class_schedule.period_start = now + 5.days
        class_schedule.enrollment_insert = now + 6.days
        expect(class_schedule.open_for_inserting_class_enrollments?).to eq(true)
        expect(class_schedule.open_for_inserting_class_enrollments?(now)).to eq(true)
      end

      it "should return true when adjust enroll insert is open" do
        now = Time.now
        class_schedule.enrollment_start = now - 5.days
        class_schedule.enrollment_end = now - 4.days
        class_schedule.period_start = now - 1.day
        class_schedule.enrollment_insert = now + 1.day
        expect(class_schedule.open_for_inserting_class_enrollments?).to eq(true)
        expect(class_schedule.open_for_inserting_class_enrollments?(now)).to eq(true)
      end

      it "should return false when neither main nor insert is open" do
        now = Time.now
        class_schedule.enrollment_start = now - 5.days
        class_schedule.enrollment_end = now - 4.days
        class_schedule.period_start = now + 1.day
        class_schedule.enrollment_insert = now + 2.days
        expect(class_schedule.open_for_inserting_class_enrollments?).to eq(false)
        expect(class_schedule.open_for_inserting_class_enrollments?(now)).to eq(false)
      end
    end

    describe "enroll open?" do
      context "main enrollment time" do
        it "should return true when time is in between the start and end dates" do
          now = Time.now
          class_schedule.enrollment_start = now - 1.day
          class_schedule.enrollment_end = now + 1.day
          class_schedule.period_start = now + 5.days
          class_schedule.enrollment_insert = now + 6.days
          class_schedule.enrollment_remove = now + 6.days
          expect(class_schedule.enroll_open?).to eq(true)
          expect(class_schedule.enroll_open?(now)).to eq(true)
        end
        it "should return false when time before the start date" do
          now = Time.now
          class_schedule.enrollment_start = now + 1.day
          class_schedule.enrollment_end = now + 2.days
          class_schedule.period_start = now + 5.days
          class_schedule.enrollment_insert = now + 6.days
          class_schedule.enrollment_remove = now + 6.days
          expect(class_schedule.enroll_open?).to eq(false)
          expect(class_schedule.enroll_open?(now - 3.days)).to eq(false)
        end
        it "should return false when time after the end date" do
          now = Time.now
          class_schedule.enrollment_start = now + 1.day
          class_schedule.enrollment_end = now + 2.days
          class_schedule.period_start = now + 5.days
          class_schedule.enrollment_insert = now + 6.days
          class_schedule.enrollment_remove = now + 6.days
          expect(class_schedule.enroll_open?(now + 3.days)).to eq(false)
        end
      end
      context "adjustment time" do
        it "should return true when time is in between the adjust and insert dates" do
          now = Time.now
          class_schedule.enrollment_start = now - 5.days
          class_schedule.enrollment_end = now - 4.days
          class_schedule.period_start = now - 1.day
          class_schedule.enrollment_insert = now + 1.day
          class_schedule.enrollment_remove = now - 1.day
          expect(class_schedule.enroll_open?).to eq(true)
          expect(class_schedule.enroll_open?(now)).to eq(true)
        end
        it "should return true when time is in between the adjust and remove dates" do
          now = Time.now
          class_schedule.enrollment_start = now - 5.days
          class_schedule.enrollment_end = now - 4.days
          class_schedule.period_start = now - 1.day
          class_schedule.enrollment_insert = now - 1.day
          class_schedule.enrollment_remove = now + 1.day
          expect(class_schedule.enroll_open?).to eq(true)
          expect(class_schedule.enroll_open?(now)).to eq(true)
        end
        it "should return true when time is in between the adjust and remove and insert dates" do
          now = Time.now
          class_schedule.enrollment_start = now - 5.days
          class_schedule.enrollment_end = now - 4.days
          class_schedule.period_start = now - 1.day
          class_schedule.enrollment_insert = now + 1.day
          class_schedule.enrollment_remove = now + 1.day
          expect(class_schedule.enroll_open?).to eq(true)
          expect(class_schedule.enroll_open?(now)).to eq(true)
        end
        it "should return false when time before the adjust date" do
          now = Time.now
          class_schedule.enrollment_start = now - 5.days
          class_schedule.enrollment_end = now - 4.days
          class_schedule.period_start = now + 1.day
          class_schedule.enrollment_insert = now + 2.days
          class_schedule.enrollment_remove = now + 2.days
          expect(class_schedule.enroll_open?).to eq(false)
          expect(class_schedule.enroll_open?(now - 3.days)).to eq(false)
        end
        it "should return false when time after both the insert and remove dates" do
          now = Time.now
          class_schedule.enrollment_start = now - 5.days
          class_schedule.enrollment_end = now - 4.days
          class_schedule.period_start = now + 1.day
          class_schedule.enrollment_insert = now + 2.days
          class_schedule.enrollment_remove = now + 2.days
          expect(class_schedule.enroll_open?(now + 3.days)).to eq(false)
        end
      end
    end

    describe "arel main enroll open?" do
      it "includes schedules where main enrollment is open" do
        result = ClassSchedule.where(ClassSchedule.arel_main_enroll_open?).where(year: [9990, 9991, 9992])
        expect(result).to include(@open_main)
        expect(result).not_to include(@open_insert)
        expect(result).not_to include(@open_remove)
        expect(result).not_to include(@closed)
      end
    end

    describe "arel adjust enroll insert open?" do
      it "includes schedules where adjustment insert enrollment is open" do
        result = ClassSchedule.where(ClassSchedule.arel_adjust_enroll_insert_open?).where(year: [9990, 9991, 9992])
        expect(result).to include(@open_insert)
        expect(result).not_to include(@open_main)
        expect(result).not_to include(@open_remove)
        expect(result).not_to include(@closed)
      end
    end

    describe "arel adjust enroll remove open?" do
      it "includes schedules where adjustment remove enrollment is open" do
        result = ClassSchedule.where(ClassSchedule.arel_adjust_enroll_remove_open?).where(year: [9990, 9991, 9992])
        expect(result).to include(@open_remove)
        expect(result).not_to include(@open_main)
        expect(result).not_to include(@open_insert)
        expect(result).not_to include(@closed)
      end
    end

    describe "arel enroll open?" do
      it "includes schedules where any enrollment period is open" do
        result = ClassSchedule.where(ClassSchedule.arel_enroll_open?).where(year: [9990, 9991, 9992])
        expect(result).to include(@open_main)
        expect(result).to include(@open_insert)
        expect(result).to include(@open_remove)
        expect(result).not_to include(@closed)
      end
    end
  end
end

