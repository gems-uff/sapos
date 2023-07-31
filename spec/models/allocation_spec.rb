# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Allocation, type: :model do
  it { should be_able_to_be_destroyed }

  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end

  let(:course_class) { FactoryBot.build(:course_class) }
  let(:allocation) do
    Allocation.new(
      course_class: course_class,
      day: I18n.translate("date.day_names").first,
      start_time: 10,
      end_time: 12
    )
  end
  subject { allocation }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:course_class).required(true) }
    it { should validate_presence_of(:day) }
    it { should validate_inclusion_of(:day).in_array(I18n.translate("date.day_names")) }
    it { should validate_presence_of(:start_time) }
    it { should validate_numericality_of(:start_time).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(23) }
    it { should validate_presence_of(:end_time) }
    it { should validate_numericality_of(:end_time).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(23) }

    describe "start_end_time_validation" do
      context "should be valid when" do
        it "end_time is greater_than_start_time" do
          allocation.start_time = (Time.now.at_beginning_of_day + 10.hours).hour
          allocation.end_time = (Time.now.at_beginning_of_day + 12.hours).hour
          expect(allocation).to have(0).errors_on :start_time
        end
      end
      context "should have error end_time_before_start_time when" do
        it "start_time is greater_than_end_time" do
          allocation.end_time = (Time.now.at_beginning_of_day + 10.hours).hour
          allocation.start_time = (Time.now.at_beginning_of_day + 12.hours).hour
          expect(allocation).to have_error(:end_time_before_start_time).on :start_time
        end
      end
    end
    describe "scheduling_conflict_validation" do
      context "should be valid when" do
        it "does not exists a scheduling conflict" do
          @destroy_later << other_allocation = FactoryBot.create(:allocation, start_time: (Time.now.at_beginning_of_day + 10.hours).hour, end_time: (Time.now.at_beginning_of_day + 12.hours).hour)
          allocation.start_time = (Time.now.at_beginning_of_day + 7.hours).hour
          allocation.end_time = (Time.now.at_beginning_of_day + 9.hours).hour
          allocation.course_class = other_allocation.course_class
          allocation.day = other_allocation.day
          expect(allocation).to have(0).errors_on :start_time
          expect(allocation).to have(0).errors_on :end_time
        end
      end
      context "should have error scheduling_conflict when" do
        it "start_time between another allocation's start_time and end_time" do
          @destroy_later << other_allocation = FactoryBot.create(:allocation, start_time: (Time.now.at_beginning_of_day + 10.hours).hour, end_time: (Time.now.at_beginning_of_day + 12.hours).hour)
          allocation.start_time = (Time.now.at_beginning_of_day + 11.hours).hour
          allocation.end_time = (Time.now.at_beginning_of_day + 13.hours).hour
          allocation.course_class = other_allocation.course_class
          allocation.day = other_allocation.day
          expect(allocation).to have_error(:scheduling_conflict).on :start_time
          expect(allocation).to have(0).errors_on :end_time
        end
        it "end_time between another allocation's start_time and end_time" do
          @destroy_later << other_allocation = FactoryBot.create(:allocation, start_time: (Time.now.at_beginning_of_day + 10.hours).hour, end_time: (Time.now.at_beginning_of_day + 12.hours).hour)
          allocation.start_time = (Time.now.at_beginning_of_day + 9.hours).hour
          allocation.end_time = (Time.now.at_beginning_of_day + 11.hours).hour
          allocation.course_class = other_allocation.course_class
          allocation.day = other_allocation.day
          expect(allocation).to have_error(:scheduling_conflict).on :end_time
          expect(allocation).to have(0).errors_on :start_time
        end
      end
    end
  end
  describe "Methods" do
    describe "intersects" do
      it "should return start_time if the start time is between the other range" do
        day = I18n.translate("date.day_names").first
        other = FactoryBot.build(:allocation, day: day, start_time: 9, end_time: 11)
        allocation.day = day
        allocation.start_time = 10
        allocation.end_time = 12
        expect(allocation.intersects(other)).to eq(:start_time)
      end
      it "should return end_time if the start time is between the other range" do
        day = I18n.translate("date.day_names").first
        other = FactoryBot.build(:allocation, day: day, start_time: 9, end_time: 11)
        allocation.day = day
        allocation.start_time = 8
        allocation.end_time = 10
        expect(allocation.intersects(other)).to eq(:end_time)
      end
      it "should return nil if it does not intersect" do
        day = I18n.translate("date.day_names").first
        other = FactoryBot.build(:allocation, day: day, start_time: 9, end_time: 11)
        allocation.day = day
        allocation.start_time = 14
        allocation.end_time = 16
        expect(allocation.intersects(other)).to eq(nil)
      end
      it "should return nil if the start matchs the other end" do
        day = I18n.translate("date.day_names").first
        other = FactoryBot.build(:allocation, day: day, start_time: 9, end_time: 11)
        allocation.day = day
        allocation.start_time = 11
        allocation.end_time = 13
        expect(allocation.intersects(other)).to eq(nil)
      end
      it "should return nil if the end matchs the other start" do
        day = I18n.translate("date.day_names").first
        other = FactoryBot.build(:allocation, day: day, start_time: 9, end_time: 11)
        allocation.day = day
        allocation.start_time = 7
        allocation.end_time = 9
        expect(allocation.intersects(other)).to eq(nil)
      end
      it "should return start_time if both times match" do
        day = I18n.translate("date.day_names").first
        other = FactoryBot.build(:allocation, day: day, start_time: 9, end_time: 11)
        allocation.day = day
        allocation.start_time = 9
        allocation.end_time = 11
        expect(allocation.intersects(other)).to eq(:start_time)
      end
    end
  end
end
