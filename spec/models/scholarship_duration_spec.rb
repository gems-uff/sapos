# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.
# frozen_string_literal: true

require "spec_helper"

RSpec.configure do |c|
  c.include DateHelpers
end

RSpec.describe ScholarshipDuration, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:scholarship_suspensions).dependent(:destroy) }

  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end

  let(:start_date) { middle_of_month 3.months.ago.to_date }
  let(:end_date) { middle_of_month 3.months.from_now.to_date }
  let(:level) { FactoryBot.build(:level) }
  let(:enrollment) { FactoryBot.build(:enrollment, level: level) }
  let(:scholarship) { FactoryBot.build(:scholarship, start_date: start_date, end_date: end_date, level: level) }
  let(:scholarship_duration) do
    scholarship.scholarship_durations.build(
      start_date: start_date,
      end_date: end_date,
      enrollment: enrollment
    )
  end
  subject { scholarship_duration }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:scholarship).required(true) }
    it { should belong_to(:enrollment).required(true) }
    it { should validate_presence_of(:start_date) }
    it { should accept_a_month_year_assignment_of(:start_date, presence: true) }
    it { should accept_a_month_year_assignment_of(:end_date) }
    it { should accept_a_month_year_assignment_of(:cancel_date) }

    describe "enrollment" do
      context "should have error taken when" do
        it "enrollment has other active scholarship" do
          @destroy_later << FactoryBot.create(:scholarship_duration, enrollment: enrollment, scholarship: scholarship,
                                                                     start_date: start_date, end_date: end_date)
          expect(scholarship_duration).to have_error(:enrollment_and_scholarship_uniqueness).on :enrollment
        end
      end
    end
    describe "start_date" do
      context "should be valid when" do
        it "is after scholarship start date" do
          scholarship_duration.start_date = start_date + 1.month
          expect(scholarship_duration).to have(0).errors_on :start_date
        end
        it "is before scholarship end date" do
          scholarship_duration.start_date = end_date - 2.months
          scholarship_duration.end_date = end_date - 1.month
          expect(scholarship_duration).to have(0).errors_on :start_date
        end
      end
      context "should have error start_date_after_end_date when" do
        it "is after end date" do
          scholarship_duration.start_date = end_date - 1.month
          scholarship_duration.end_date = end_date - 2.months
          expect(scholarship_duration).to have_error(:start_date_after_end_date).on :start_date
        end
      end
      context "should have error start_date_before_scholarship_start_date when" do
        it "is before scholarship start date" do
          scholarship_duration.start_date = start_date - 1.month
          expect(scholarship_duration).to have_error(:start_date_before_scholarship_start_date).on :start_date
        end
      end
    end
    describe "end_date" do
      context "is valid and greater than scholarship.end_date" do
        it "there must be a cancel_date less than or equal scholarship.end_date" do
          scholarship_duration.end_date = scholarship.end_date + 1.month
          scholarship_duration.cancel_date = scholarship.end_date
          expect(scholarship_duration).to have(0).errors_on :end_date
        end
      end
      context "should have error end_date_after_scholarship_end_date when" do
        it "is after the scholarship end date and there is no cancel_date" do
          scholarship_duration.end_date = scholarship.end_date + 1.month
          scholarship_duration.cancel_date = nil
          expect(scholarship_duration).to have_error(:end_date_after_scholarship_end_date).on :end_date
        end
      end
    end
    describe "cancel_date" do
      context "should have error cancel_date_before_start_date when" do
        it "is before the start date" do
          scholarship_duration.cancel_date = scholarship.start_date - 1.month
          expect(scholarship_duration).to have_error(:cancel_date_before_start_date).on :cancel_date
        end
      end
      context "should have error cancel_date_after_end_date when" do
        it "is after the end date" do
          scholarship_duration.end_date = end_date - 1.month
          scholarship_duration.cancel_date = end_date
          expect(scholarship_duration).to have_error(:cancel_date_after_end_date).on :cancel_date
        end
        it "is after the scholarship end date" do
          scholarship_duration.cancel_date = end_date + 2.months
          expect(scholarship_duration).to have_error(:cancel_date_after_scholarship_end_date).on :cancel_date
        end
      end
    end
    describe "if_scholarship_is_not_with_another_student" do
      context "should return the expected error when" do
        it "has an old scholarship that ends after the new scholarship starts" do
          scholarship.update(end_date: end_date + 2.months)
          @destroy_later << scholarship if scholarship.save
          @destroy_later << FactoryBot.create(
            :scholarship_duration, enrollment: enrollment, scholarship: scholarship,
                                   start_date: start_date, end_date: end_date + 2.months
          )
          scholarship_duration.start_date = end_date
          scholarship_duration.end_date = end_date + 5.months
          expect(scholarship_duration).to have_error(:start_date_before_scholarship_end_date).on :start_date
        end
        it "has an old scholarship that was canceled after the new scholarship starts" do
          scholarship.update(end_date: end_date + 2.months)
          @destroy_later << scholarship if scholarship.save
          @destroy_later << FactoryBot.create(
            :scholarship_duration, enrollment: enrollment, scholarship: scholarship,
                                   start_date: start_date, end_date: end_date + 2.months,
                                   cancel_date: end_date + 1.month
          )
          scholarship_duration.start_date = end_date
          scholarship_duration.end_date = end_date + 5.months
          expect(scholarship_duration).to have_error(:start_date_before_scholarship_cancel_date).on :start_date
        end
        it "has an new scholarship that starts before the scholarship ends" do
          scholarship.update(end_date: end_date + 2.months)
          @destroy_later << scholarship if scholarship.save
          @destroy_later << FactoryBot.create(
            :scholarship_duration, enrollment: enrollment, scholarship: scholarship,
                                   start_date: end_date, end_date: end_date + 2.months
          )
          scholarship_duration.start_date = start_date
          scholarship_duration.end_date = end_date + 1.month
          expect(scholarship_duration).to have_error(:scholarship_start_date_after_end_or_cancel_date).on :end_date
        end
        it "has an new scholarship that is canceled before the scholarship ends" do
          scholarship.update(end_date: end_date + 2.months)
          @destroy_later << scholarship if scholarship.save
          @destroy_later << FactoryBot.create(
            :scholarship_duration, enrollment: enrollment, scholarship: scholarship,
                                   start_date: end_date, end_date: end_date + 2.months
          )
          scholarship_duration.end_date = end_date + 2.months
          scholarship_duration.cancel_date = end_date + 1.month
          expect(scholarship_duration).to have_error(:scholarship_start_date_after_end_or_cancel_date).on :cancel_date
        end
      end
    end
  end
  describe "Methods" do
    describe "student_has_other_scholarship_duration" do
      context "should return true when" do
        it "has an old scholarship that ends after the new scholarship starts" do
          @destroy_later << FactoryBot.create(
            :scholarship_duration, enrollment: enrollment, scholarship: scholarship,
                                   start_date: start_date, end_date: end_date
          )
          expect(scholarship_duration.student_has_other_scholarship_duration).to be_truthy
        end
        it "has an old scholarship that was canceled after the new scholarship starts" do
          scholarship.update(end_date: end_date + 2.months)
          @destroy_later << scholarship if scholarship.save
          @destroy_later << FactoryBot.create(
            :scholarship_duration, enrollment: enrollment, scholarship: scholarship,
                                   start_date: start_date, end_date: end_date + 2.months,
                                   cancel_date: end_date + 1.month
          )
          @destroy_later << scholarship_duration.scholarship = FactoryBot.create(
            :scholarship, start_date: end_date, end_date: end_date + 5.months
          )
          scholarship_duration.start_date = end_date
          scholarship_duration.end_date = end_date + 5.months
          expect(scholarship_duration.student_has_other_scholarship_duration).to be_truthy
        end
        it "has an new scholarship that starts before the scholarship ends" do
          scholarship.update(end_date: end_date + 2.months)
          @destroy_later << scholarship if scholarship.save
          @destroy_later << FactoryBot.create(
            :scholarship_duration, enrollment: enrollment, scholarship: scholarship,
                                   start_date: start_date, end_date: end_date + 2.months
          )
          @destroy_later << scholarship_duration.scholarship = FactoryBot.create(
            :scholarship, start_date: start_date, end_date: end_date + 1.month
          )
          scholarship_duration.end_date = end_date + 1.month
          expect(scholarship_duration.student_has_other_scholarship_duration).to be_truthy
        end

        it "has an new scholarship that is canceled before the scholarship ends" do
          scholarship.update(end_date: end_date + 2.months)
          @destroy_later << scholarship if scholarship.save
          @destroy_later << FactoryBot.create(
            :scholarship_duration, enrollment: enrollment, scholarship: scholarship,
                                   start_date: start_date, end_date: end_date + 2.months
          )
          @destroy_later << scholarship_duration.scholarship = FactoryBot.create(
            :scholarship, start_date: start_date, end_date: end_date + 2.months
          )
          scholarship_duration.end_date = end_date + 2.months
          scholarship_duration.cancel_date = end_date + 1.month
          expect(scholarship_duration.student_has_other_scholarship_duration).to be_truthy
        end
      end
    end
    describe "to_label" do
      it "should return the expected string" do
        scholarship_duration.start_date = start_date
        scholarship_duration.end_date = end_date
        expect(scholarship_duration.to_label).to eql("#{I18n.localize(start_date, format: :monthyear)} - "\
                                                     "#{I18n.localize(end_date, format: :monthyear)}")
      end
    end
    describe "warning_message" do
      it "should return nil when everything is alright" do
        scholarship.update(end_date: end_date + 5.months)
        @destroy_later << scholarship if scholarship.save
        @destroy_later << FactoryBot.create(
          :scholarship_duration, enrollment: enrollment, scholarship: scholarship,
                                 start_date: end_date, end_date: end_date + 2.months,
                                 cancel_date: end_date + 2.months
        )
        scholarship_duration.start_date = end_date + 3.months
        scholarship_duration.end_date = end_date + 5.months
        expect(scholarship_duration.warning_message).to be_nil
      end

      it "should return unfinished scholarship warning when there is an unfinished scholarship" do
        scholarship.update(end_date: end_date + 5.months)
        @destroy_later << scholarship if scholarship.save
        @destroy_later << FactoryBot.create(
          :scholarship_duration, enrollment: enrollment, scholarship: scholarship,
                                 start_date: end_date, end_date: end_date + 2.months
        )
        scholarship_duration.start_date = end_date + 3.months
        scholarship_duration.end_date = end_date + 5.months
        expect(scholarship_duration.warning_message).to eq(
          I18n.t("activerecord.errors.models.scholarship_duration.unfinished_scholarship")
        )
      end
    end
    describe "last_date" do
      it "should return end_date.end_of_month if there is no cancel_date" do
        scholarship_duration.end_date = end_date + 2.months
        expect(scholarship_duration.last_date).to eq((end_date + 2.months).end_of_month)
      end
      it "should return cancel_date.end_of_month if there is a cancel_date" do
        scholarship_duration.end_date = end_date + 2.months
        scholarship_duration.cancel_date = end_date + 1.month
        expect(scholarship_duration.last_date).to eq((end_date + 1.months).end_of_month)
      end
    end
    describe "was_cancelled?" do
      it "should return false if there is no cancel_date" do
        scholarship_duration.end_date = end_date + 2.months
        scholarship_duration.cancel_date = nil
        expect(scholarship_duration.was_cancelled?).to eq(false)
      end
      it "should return false if cancel_date == end_date" do
        scholarship_duration.end_date = end_date + 2.months
        scholarship_duration.cancel_date = end_date + 2.months
        expect(scholarship_duration.was_cancelled?).to eq(false)
      end
      it "should return true if cancel_date != end_date" do
        scholarship_duration.end_date = end_date + 2.months
        scholarship_duration.cancel_date = end_date + 1.month
        expect(scholarship_duration.was_cancelled?).to eq(true)
      end
    end
    describe "active?" do
      it "should return false if date is after end_date" do
        scholarship_duration.end_date = end_date + 2.months
        scholarship_duration.cancel_date = nil
        expect(scholarship_duration.active?(date: end_date + 4.months)).to eq(false)
      end
      it "should return false if date is in the month of cancel_date" do
        scholarship_duration.end_date = end_date + 2.months
        scholarship_duration.cancel_date = end_date + 2.months
        expect(scholarship_duration.active?(date: scholarship_duration.cancel_date - 1.day)).to eq(false)
      end
      it "should return false if date < start_date" do
        scholarship_duration.start_date = end_date
        scholarship_duration.end_date = end_date + 2.months
        scholarship_duration.cancel_date = end_date + 2.months
        expect(scholarship_duration.active?(date: end_date - 1.month)).to eq(false)
      end
      it "should return true if date < cancel_date" do
        scholarship_duration.end_date = end_date + 2.months
        scholarship_duration.cancel_date = end_date + 1.month
        expect(scholarship_duration.active?(date: end_date.end_of_month)).to eq(true)
      end
    end
  end
end
