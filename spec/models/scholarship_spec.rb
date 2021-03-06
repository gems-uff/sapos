# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Scholarship do
  it { should be_able_to_be_destroyed }
  it { should destroy_dependent :scholarship_duration }

  let(:scholarship) { Scholarship.new }
  subject { scholarship }
  describe "Validations" do
    describe "level" do
      context "should be valid when" do
        it "level is not null" do
          scholarship.level = Level.new
          expect(scholarship).to have(0).errors_on :level
        end
      end
      context "should have error blank when" do
        it "level is null" do
          scholarship.level = nil
          expect(scholarship).to have_error(:blank).on :level
        end
      end
    end
    describe "sponsor" do
      context "should be valid when" do
        it "sponsor is not null" do
          scholarship.sponsor = Sponsor.new
          expect(scholarship).to have(0).errors_on :sponsor
        end
      end
      context "should have error blank when" do
        it "sponsor is null" do
          scholarship.sponsor = nil
          expect(scholarship).to have_error(:blank).on :sponsor
        end
      end
    end
    describe "start_date" do
      context "is after scholarship_duration.start_date" do
        scholarship_duration = ScholarshipDuration.new
        it "should return an error message" do
          scholarship.start_date = Date.today
          scholarship_duration.scholarship = scholarship
          scholarship_duration.start_date  = scholarship.start_date - 1.day
          scholarship.validate
          expect(scholarship_duration).to have_error(:start_date_before_scholarship_start_date).on :start_date
        end
      end
    end
    describe "end_date" do
      context "is before scholarship_duration.end_date and scholarship.cancel_date is nil" do
        scholarship_duration = ScholarshipDuration.new
        it "should return an error message" do
          scholarship.end_date = Date.today
          scholarship_duration.scholarship = scholarship
          scholarship_duration.end_date  = scholarship.end_date + 1.day
          scholarship_duration.cancel_date = nil
          scholarship.validate
          expect(scholarship_duration).to have_error(:end_date_after_scholarship_end_date).on :end_date
        end
      end
      context "is before scholarship_duration.cancel_date" do
        scholarship_duration = ScholarshipDuration.new
        it "should return an error message" do
          scholarship.end_date = Date.today
          scholarship_duration.scholarship = scholarship
          scholarship_duration.cancel_date  = scholarship.end_date + 1.day
          scholarship.validate
          expect(scholarship_duration).to have_error(:cancel_date_after_scholarship_end_date).on :cancel_date
        end
      end
      context "should be valid when" do
        it "end_date is greater than start_date" do
          scholarship.end_date = Date.today
          scholarship.start_date = 1.day.ago
          expect(scholarship).to have(0).errors_on :end_date
        end
      end
      context "should have error on_or_after when" do
        it "start_date is greater than end_date" do
          scholarship.start_date = 2.days.from_now
          scholarship.end_date = 2.days.ago
          expect(scholarship).to have_error(:on_or_after).on :end_date
        end
      end
    end
    describe "scholarship_number" do
      context "should be valid when" do
        it "scholarship_number is not null and is not taken" do
          scholarship.scholarship_number = "M123"
          expect(scholarship).to have(0).errors_on :scholarship_number
        end
      end
      context "should have error blank when" do
        it "scholarship_number is null" do
          scholarship.scholarship_number = nil
          expect(scholarship).to have_error(:blank).on :scholarship_number
        end
      end
      context "should have error taken when" do
        it "scholarship_number is already in use" do
          scholarship_number = "D123"
          FactoryBot.create(:scholarship, :scholarship_number => scholarship_number)
          scholarship.scholarship_number = scholarship_number
          expect(scholarship).to have_error(:taken).on :scholarship_number
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        scholarship_number = 123
        scholarship.scholarship_number = scholarship_number
        expect(scholarship.to_label).to eql("#{scholarship_number}")
      end
    end

    describe 'last_date' do
      let(:end_date) { 3.days.from_now.to_date }

      it 'should return end_date.end_of_month if there is end_date' do
        scholarship = FactoryBot.create(:scholarship, :start_date => end_date, :end_date => end_date + 2.months)
        expect(scholarship.last_date).to eq((end_date + 2.months).end_of_month)
      end

      it 'should be greater or equal to 100 years if there is no end_date' do
        scholarship = FactoryBot.create(:scholarship, :start_date => end_date, :end_date => nil)
        expect(scholarship.last_date).to be >= Date.today + 100.years - 1.day
      end
    end
  end
end
