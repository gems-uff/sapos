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
      enrollment_adjust: Time.now,
      enrollment_insert: Time.now,
      enrollment_remove: Time.now
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
    it { should validate_presence_of(:enrollment_adjust) }
    it { should validate_presence_of(:enrollment_insert) }
    it { should validate_presence_of(:enrollment_remove) }
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
        class_schedule.enrollment_adjust = now - 1.day
        class_schedule.enrollment_insert = now + 1.day
        expect(class_schedule.adjust_enroll_insert_open?).to eq(true)
        expect(class_schedule.adjust_enroll_insert_open?(now)).to eq(true)
      end
      it "should return false when time before the adjust date" do
        now = Time.now
        class_schedule.enrollment_adjust = now + 1.day
        class_schedule.enrollment_insert = now + 2.days
        expect(class_schedule.adjust_enroll_insert_open?).to eq(false)
        expect(class_schedule.adjust_enroll_insert_open?(now - 3.days)).to eq(false)
      end
      it "should return false when time after both the insert and remove dates" do
        now = Time.now
        class_schedule.enrollment_adjust = now + 1.day
        class_schedule.enrollment_insert = now + 2.days
        expect(class_schedule.adjust_enroll_insert_open?(now + 3.days)).to eq(false)
      end
    end
    describe "adjust_enroll_remove_open?" do
      it "should return true when time is in between the adjust and remove dates" do
        now = Time.now
        class_schedule.enrollment_adjust = now - 1.day
        class_schedule.enrollment_remove = now + 1.day
        expect(class_schedule.adjust_enroll_remove_open?).to eq(true)
        expect(class_schedule.adjust_enroll_remove_open?(now)).to eq(true)
      end
      it "should return false when time before the adjust date" do
        now = Time.now
        class_schedule.enrollment_adjust = now + 1.day
        class_schedule.enrollment_remove = now + 2.days
        expect(class_schedule.adjust_enroll_remove_open?).to eq(false)
        expect(class_schedule.adjust_enroll_remove_open?(now - 3.days)).to eq(false)
      end
      it "should return false when time after both the insert and remove dates" do
        now = Time.now
        class_schedule.enrollment_adjust = now + 1.day
        class_schedule.enrollment_remove = now + 2.days
        expect(class_schedule.adjust_enroll_remove_open?(now + 3.days)).to eq(false)
      end
    end
    describe "enroll_open?" do
      context "main enrollment time" do
        it "should return true when time is in between the start and end dates" do
          now = Time.now
          class_schedule.enrollment_start = now - 1.day
          class_schedule.enrollment_end = now + 1.day
          class_schedule.enrollment_adjust = now + 5.days
          class_schedule.enrollment_insert = now + 6.days
          class_schedule.enrollment_remove = now + 6.days
          expect(class_schedule.enroll_open?).to eq(true)
          expect(class_schedule.enroll_open?(now)).to eq(true)
        end
        it "should return false when time before the start date" do
          now = Time.now
          class_schedule.enrollment_start = now + 1.day
          class_schedule.enrollment_end = now + 2.days
          class_schedule.enrollment_adjust = now + 5.days
          class_schedule.enrollment_insert = now + 6.days
          class_schedule.enrollment_remove = now + 6.days
          expect(class_schedule.enroll_open?).to eq(false)
          expect(class_schedule.enroll_open?(now - 3.days)).to eq(false)
        end
        it "should return false when time after the end date" do
          now = Time.now
          class_schedule.enrollment_start = now + 1.day
          class_schedule.enrollment_end = now + 2.days
          class_schedule.enrollment_adjust = now + 5.days
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
          class_schedule.enrollment_adjust = now - 1.day
          class_schedule.enrollment_insert = now + 1.day
          class_schedule.enrollment_remove = now - 1.day
          expect(class_schedule.enroll_open?).to eq(true)
          expect(class_schedule.enroll_open?(now)).to eq(true)
        end
        it "should return true when time is in between the adjust and remove dates" do
          now = Time.now
          class_schedule.enrollment_start = now - 5.days
          class_schedule.enrollment_end = now - 4.days
          class_schedule.enrollment_adjust = now - 1.day
          class_schedule.enrollment_insert = now - 1.day
          class_schedule.enrollment_remove = now + 1.day
          expect(class_schedule.enroll_open?).to eq(true)
          expect(class_schedule.enroll_open?(now)).to eq(true)
        end
        it "should return true when time is in between the adjust and remove and insert dates" do
          now = Time.now
          class_schedule.enrollment_start = now - 5.days
          class_schedule.enrollment_end = now - 4.days
          class_schedule.enrollment_adjust = now - 1.day
          class_schedule.enrollment_insert = now + 1.day
          class_schedule.enrollment_remove = now + 1.day
          expect(class_schedule.enroll_open?).to eq(true)
          expect(class_schedule.enroll_open?(now)).to eq(true)
        end
        it "should return false when time before the adjust date" do
          now = Time.now
          class_schedule.enrollment_start = now - 5.days
          class_schedule.enrollment_end = now - 4.days
          class_schedule.enrollment_adjust = now + 1.day
          class_schedule.enrollment_insert = now + 2.days
          class_schedule.enrollment_remove = now + 2.days
          expect(class_schedule.enroll_open?).to eq(false)
          expect(class_schedule.enroll_open?(now - 3.days)).to eq(false)
        end
        it "should return false when time after both the insert and remove dates" do
          now = Time.now
          class_schedule.enrollment_start = now - 5.days
          class_schedule.enrollment_end = now - 4.days
          class_schedule.enrollment_adjust = now + 1.day
          class_schedule.enrollment_insert = now + 2.days
          class_schedule.enrollment_remove = now + 2.days
          expect(class_schedule.enroll_open?(now + 3.days)).to eq(false)
        end
      end
    end
  end
end
