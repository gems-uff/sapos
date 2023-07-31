# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Scholarship, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:scholarship_durations).dependent(:destroy) }
  it { should have_many(:enrollments).through(:scholarship_durations) }

  let(:start_date) { 3.months.ago.to_date }
  let(:end_date) { 3.months.from_now.to_date }
  let(:scholarship_number) { "M123" }
  let(:sponsor) { FactoryBot.build(:sponsor) }
  let(:level) { FactoryBot.build(:level) }
  let(:scholarship) do
    Scholarship.new(
      scholarship_number: scholarship_number,
      level: level,
      sponsor: sponsor,
      start_date: start_date,
      end_date: end_date
    )
  end
  subject { scholarship }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:level).required(true) }
    it { should belong_to(:sponsor).required(true) }
    it { should belong_to(:scholarship_type).required(false) }
    it { should belong_to(:professor).required(false) }
    it { should validate_uniqueness_of(:scholarship_number) }
    it { should validate_presence_of(:scholarship_number) }
    it { should accept_a_month_year_assignment_of(:start_date, presence: true) }
    it { should validate_presence_of(:start_date) }
    it { should accept_a_month_year_assignment_of(:end_date) }

    describe "end_date" do
      context "should be valid when" do
        it "end_date is greater than start_date" do
          scholarship.end_date = start_date + 1.month
          expect(scholarship).to have(0).errors_on :end_date
        end
      end
      context "should have error on_or_after when" do
        it "start_date is greater than end_date" do
          scholarship.end_date = start_date - 1.month
          expect(scholarship).to have_error(:on_or_after).on :end_date
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        expect(scholarship.to_label).to eql(scholarship_number.to_s)
      end
    end
    describe "last_date" do
      let(:end_date) { 3.days.from_now.to_date }
      it "should return end_date.end_of_month if there is end_date" do
        scholarship.end_date = end_date + 2.months
        expect(scholarship.last_date).to eq((end_date + 2.months).end_of_month)
      end
      it "should be greater or equal to 100 years if there is no end_date" do
        scholarship.end_date = nil
        expect(scholarship.last_date).to be >= Date.today + 100.years - 1.day
      end
    end
  end
end
