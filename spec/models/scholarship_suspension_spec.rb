# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'spec_helper'

describe ScholarshipSuspension do
  let(:scholarship_suspension) { ScholarshipSuspension.new }
  let(:start_date) { 3.days.ago.to_date }
  let(:end_date) { 3.days.from_now.to_date }
  subject { scholarship_duration }
  describe "Validations" do
    describe "scholarship_duration" do
      context "should be valid when" do
        it "scholarship_duration is not null" do
          scholarship_suspension.scholarship_duration = ScholarshipDuration.new
          expect(scholarship_suspension).to have(0).errors_on :scholarship_duration
        end
      end
      context "should have error when" do
        it "scholarship_duration is null" do
          scholarship_suspension.scholarship_duration = nil
          expect(scholarship_suspension).to have_error(:blank).on :scholarship_duration
        end
      end
    end
    describe "start_date" do
      context "should be valid when" do
        it "is after scholarship_duration start date" do
          scholarship_duration = FactoryBot.create(:scholarship_duration)
          scholarship_suspension.scholarship_duration = scholarship_duration
          scholarship_suspension.start_date = scholarship_duration.start_date + 1.day
          scholarship_suspension.end_date = scholarship_duration.end_date
          expect(scholarship_suspension).to have(0).errors_on :start_date
        end
        it "is before scholarship_duration end date" do
          scholarship_duration = FactoryBot.create(:scholarship_duration)
          scholarship_suspension.scholarship_duration = scholarship_duration
          scholarship_suspension.start_date = scholarship_duration.end_date - 1.day
          scholarship_suspension.end_date = scholarship_duration.end_date
          expect(scholarship_suspension).to have(0).errors_on :start_date
        end
        it "is before end date" do
          scholarship_duration = FactoryBot.create(:scholarship_duration)
          scholarship_suspension.scholarship_duration = scholarship_duration
          scholarship_suspension.start_date = scholarship_duration.end_date - 1.day
          scholarship_suspension.end_date = scholarship_duration.end_date
          expect(scholarship_suspension).to have(0).errors_on :start_date
        end
      end
      context "should have error when" do
        it "is before scholarship_duration start date" do
          scholarship_duration = FactoryBot.create(:scholarship_duration)
          scholarship_suspension.scholarship_duration = scholarship_duration
          scholarship_suspension.start_date = scholarship_duration.start_date - 1.day
          scholarship_suspension.end_date = scholarship_duration.end_date
          expect(scholarship_suspension).to have_error(:suspension_start_date_before_scholarship_start_date).on :start_date
        end
        it "is after scholarship_duration end date" do
          scholarship_duration = FactoryBot.create(:scholarship_duration)
          scholarship_suspension.scholarship_duration = scholarship_duration
          scholarship_suspension.start_date = scholarship_duration.end_date + 1.day
          scholarship_suspension.end_date = scholarship_duration.end_date + 2.day
          expect(scholarship_suspension).to have_error(:suspension_start_date_after_scholarship_end_date).on :start_date
        end
        it "is after end date" do
          scholarship_duration = FactoryBot.create(:scholarship_duration)
          scholarship_suspension.scholarship_duration = scholarship_duration
          scholarship_suspension.start_date = scholarship_duration.end_date + 1.day
          scholarship_suspension.end_date = scholarship_duration.end_date
          expect(scholarship_suspension).to have_error(:suspension_start_date_after_end_date).on :start_date
        end
        it "is null" do
          scholarship_suspension.start_date =  nil
          expect(scholarship_suspension).to have_error(:blank).on :start_date
        end
      end
    end
    describe "end_date" do
      context "should be valid when" do
        it "is before scholarship_duration end date" do
          scholarship_duration = FactoryBot.create(:scholarship_duration)
          scholarship_suspension.scholarship_duration = scholarship_duration
          scholarship_suspension.start_date = scholarship_duration.start_date
          scholarship_suspension.end_date = scholarship_duration.end_date - 1.day
          expect(scholarship_suspension).to have(0).errors_on :end_date
        end
      end
      context "should have error when" do
        it "is after scholarship_duration end date" do
          scholarship_duration = FactoryBot.create(:scholarship_duration)
          scholarship_suspension.scholarship_duration = scholarship_duration
          scholarship_suspension.start_date = scholarship_duration.end_date - 1.day
          scholarship_suspension.end_date = scholarship_duration.end_date + 2.day
          expect(scholarship_suspension).to have_error(:suspension_end_date_after_scholarship_end_date).on :end_date
        end
        it "is null" do
          scholarship_suspension.end_date =  nil
          expect(scholarship_suspension).to have_error(:blank).on :end_date
        end
      end
    end
    describe "if_there_is_no_other_active_suspension" do
      context "should be valid when" do
        it "is not active" do
          ss = FactoryBot.create(
            :scholarship_suspension, 
            :active => true)
          scholarship_suspension.scholarship_duration = ss.scholarship_duration 
          scholarship_suspension.start_date = ss.start_date
          scholarship_suspension.end_date = ss.end_date
          scholarship_suspension.active = false
          expect(scholarship_suspension.valid?).to be_truthy
          expect(scholarship_suspension.errors.full_messages).not_to include(I18n.t("activerecord.errors.models.scholarship_suspension.active_suspension"))
        end
      end
      context "should have error when" do
        it "there is a suspension overlap" do
          ss = FactoryBot.create(
            :scholarship_suspension, 
            :active => true)
          scholarship_suspension.scholarship_duration = ss.scholarship_duration 
          scholarship_suspension.start_date = ss.start_date
          scholarship_suspension.end_date = ss.end_date
          expect(scholarship_suspension.valid?).to be_falsey
          expect(scholarship_suspension.errors.full_messages).to include(I18n.t("activerecord.errors.models.scholarship_suspension.active_suspension"))
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        scholarship_suspension.start_date = start_date
        scholarship_suspension.end_date = end_date
        scholarship_suspension.active = true
        expect(scholarship_suspension.to_label).to eql("#{I18n.localize(start_date, :format => :monthyear)} - #{I18n.localize(end_date, :format => :monthyear)}: Bolsa Suspensa")
      end
      
    end
  end
end
