# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
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
          scholarship.should have(0).errors_on :level
        end
      end
      context "should have error blank when" do
        it "level is null" do
          scholarship.level = nil
          scholarship.should have_error(:blank).on :level
        end
      end
    end
    describe "sponsor" do
      context "should be valid when" do
        it "sponsor is not null" do
          scholarship.sponsor = Sponsor.new
          scholarship.should have(0).errors_on :sponsor
        end
      end
      context "should have error blank when" do
        it "sponsor is null" do
          scholarship.sponsor = nil
          scholarship.should have_error(:blank).on :sponsor
        end
      end
    end
    describe "end_date" do
      context "should be valid when" do
        it "end_date is greater than start_date" do
          scholarship.end_date = Date.today
          scholarship.start_date = 1.day.ago
          scholarship.should have(0).errors_on :end_date
        end
      end
      context "should have error on_or_after when" do
        it "start_date is greater than end_date" do
          scholarship.start_date = 2.days.from_now
          scholarship.end_date = 2.days.ago
          scholarship.should have_error(:on_or_after).on :end_date
        end
      end
    end
    describe "scholarship_number" do
      context "should be valid when" do
        it "scholarship_number is not null and is not taken" do
          scholarship.scholarship_number = "M123"
          scholarship.should have(0).errors_on :scholarship_number
        end
      end
      context "should have error blank when" do
        it "scholarship_number is null" do
          scholarship.scholarship_number = nil
          scholarship.should have_error(:blank).on :scholarship_number
        end
      end
      context "should have error taken when" do
        it "scholarship_number is already in use" do
          scholarship_number = "D123"
          FactoryGirl.create(:scholarship, :scholarship_number => scholarship_number)
          scholarship.scholarship_number = scholarship_number
          scholarship.should have_error(:taken).on :scholarship_number
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        scholarship_number = 123
        scholarship.scholarship_number = scholarship_number
        scholarship.to_label.should eql("#{scholarship_number}")
      end
    end

    describe 'last_date' do
      let(:end_date) { 3.days.from_now.to_date }

      it 'should return end_date.end_of_month if there is end_date' do
        scholarship = FactoryGirl.create(:scholarship, :start_date => end_date, :end_date => end_date + 2.months)
        scholarship.last_date.should == (end_date + 2.months).end_of_month
      end

      it 'should be greater or equal to 100 years if there is no end_date' do
        scholarship = FactoryGirl.create(:scholarship, :start_date => end_date, :end_date => nil)
        scholarship.last_date.should >= Date.today + 100.years - 1.day
      end
    end
  end
end