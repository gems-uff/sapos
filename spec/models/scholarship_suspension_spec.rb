# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe ScholarshipSuspension, type: :model do
  let(:start_date) { 3.months.ago.to_date }
  let(:end_date) { 3.months.from_now.to_date }
  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end

  let(:level) { FactoryBot.build(:level) }
  let(:enrollment) { FactoryBot.build(:enrollment, level: level) }
  let(:scholarship) { FactoryBot.build(:scholarship, start_date: start_date, end_date: end_date, level: level) }
  let(:scholarship_duration) do
    scholarship.scholarship_durations.build(start_date: start_date, end_date: end_date, enrollment: enrollment)
  end
  let(:scholarship_suspension) do
    scholarship_duration.scholarship_suspensions.build(
      start_date: start_date,
      end_date: end_date,
      active: true
    )
  end

  subject { scholarship_suspension }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:scholarship_duration).required(true) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    it { should accept_a_month_year_assignment_of(:start_date, presence: true) }
    it { should accept_a_month_year_assignment_of(:end_date, presence: true) }

    describe "start_date" do
      context "should be valid when" do
        it "is after scholarship_duration start date" do
          scholarship_suspension.start_date = start_date + 1.month
          expect(scholarship_suspension).to have(0).errors_on :start_date
        end
        it "is before scholarship_duration end date" do
          scholarship_suspension.start_date = end_date - 1.month
          expect(scholarship_suspension).to have(0).errors_on :start_date
        end
        it "is before end date" do
          scholarship_suspension.start_date = end_date - 1.month
          expect(scholarship_suspension).to have(0).errors_on :start_date
        end
      end
      context "should have error when" do
        it "is before scholarship_duration start date" do
          scholarship_suspension.start_date = start_date - 1.month
          expect(scholarship_suspension).to have_error(:suspension_start_date_before_scholarship_start_date)
            .on :start_date
        end
        it "is after scholarship_duration end date" do
          scholarship_suspension.start_date = end_date + 1.month
          scholarship_suspension.end_date = end_date + 2.months
          expect(scholarship_suspension).to have_error(:suspension_start_date_after_scholarship_end_date).on :start_date
        end
        it "is after end date" do
          scholarship_suspension.start_date = end_date + 1.month
          scholarship_suspension.end_date = end_date
          expect(scholarship_suspension).to have_error(:suspension_start_date_after_end_date).on :start_date
        end
      end
    end
    describe "end_date" do
      context "should be valid when" do
        it "is before scholarship_duration end date" do
          scholarship_suspension.end_date = end_date - 1.month
          expect(scholarship_suspension).to have(0).errors_on :end_date
        end
      end
      context "should have error when" do
        it "is after scholarship_duration end date" do
          scholarship_suspension.start_date = end_date - 1.month
          scholarship_suspension.end_date = end_date + 2.months
          expect(scholarship_suspension).to have_error(:suspension_end_date_after_scholarship_end_date).on :end_date
        end
      end
    end
    describe "if_there_is_no_other_active_suspension" do
      context "should be valid when" do
        it "is not active" do
          @destroy_later << FactoryBot.create(
            :scholarship_suspension, active: false, scholarship_duration: scholarship_duration,
                                     start_date: start_date, end_date: end_date
          )
          expect(scholarship_suspension.valid?).to be_truthy
          expect(scholarship_suspension).not_to have_error(:active_suspension).on :base
        end
      end
      context "should have error when" do
        it "there is a suspension overlap" do
          @destroy_later << FactoryBot.create(
            :scholarship_suspension, active: true, scholarship_duration: scholarship_duration,
                                     start_date: start_date, end_date: end_date
          )
          expect(scholarship_suspension.valid?).to be_falsey
          expect(scholarship_suspension).to have_error(:active_suspension).on :base
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        expect(scholarship_suspension.to_label).to eql(
          "#{I18n.localize(start_date, format: :monthyear)} - "\
          "#{I18n.localize(end_date, format: :monthyear)}: "\
          "#{ScholarshipSuspension::ACTIVE}"
        )
      end
    end
    describe "active_label" do
      it "should return active when it is active" do
        expect(scholarship_suspension.active_label).to eql(
          ScholarshipSuspension::ACTIVE
        )
      end
      it "should return inactive when it is inactive" do
        scholarship_suspension.active = false
        expect(scholarship_suspension.active_label).to eql(
          ScholarshipSuspension::INACTIVE
        )
      end
    end
  end
end
