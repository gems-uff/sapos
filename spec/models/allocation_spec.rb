require "spec_helper"

describe Allocation do
  let(:allocation) { Allocation.new }
  subject { allocation }
  describe "Validations" do
    describe "course_class" do
      context "should be valid when" do
        it "course_class is not null" do
          allocation.course_class = CourseClass.new
          allocation.should have(0).errors_on :course_class
        end
      end
      context "should have error blank when" do
        it "course_class is null" do
          allocation.course_class = nil
          allocation.should have_error(:blank).on :course_class
        end
      end
    end
    describe "start_time" do
      context "should be valid when" do
        it "start_time is not null" do
          allocation.start_time = Time.now
          allocation.should have(0).errors_on :start_time
        end
      end
      context "should have error blank when" do
        it "start_time is null" do
          allocation.start_time = nil
          allocation.should have_error(:blank).on :start_time
        end
      end
    end
    describe "day" do
      context "should be valid when" do
        it "day is in the list" do
          allocation.day = I18n.translate("date.day_names").first
          allocation.should have(0).errors_on :day
        end
      end
      context "should have error blank when" do
        it "day is null" do
          allocation.day = nil
          allocation.should have_error(:blank).on :day
        end
      end
      context "should have error inclusion when" do
        it "day is not in the list" do
          allocation.day = "ANYTHING NOT IN THE LIST"
          allocation.should have_error(:inclusion).on :day
        end
      end
    end
    describe "end_time" do
      context "should be valid when" do
        it "end_time is not null" do
          allocation.end_time = Time.now
          allocation.should have(0).errors_on :end_time
        end
      end
      context "should have error blank when" do
        it "end_time is null" do
          allocation.end_time = nil
          allocation.should have_error(:blank).on :end_time
        end
      end
    end
    describe "start_end_time_validation" do
      context "should be valid when" do
        it "end_time is greater_than_start_time" do
          allocation.start_time = Time.now.at_beginning_of_day + 10.hours
          allocation.end_time = Time.now.at_beginning_of_day + 12.hours
          allocation.should have(0).errors_on :start_time
        end
      end
      context "should have error end_time_before_start_time when" do
        it "start_time is greater_than_end_time" do
          allocation.end_time = Time.now.at_beginning_of_day + 10.hours
          allocation.start_time = Time.now.at_beginning_of_day + 12.hours
          allocation.should have_error(:end_time_before_start_time).on :start_time
        end
      end
    end
    describe "scheduling_conflict_validation" do
      context "should be valid when" do
        it "does not exists a scheduling conflict" do
          other_allocation = Factory.create(:allocation, :start_time => Time.now.at_beginning_of_day + 10.hours, :end_time => Time.now.at_beginning_of_day + 12.hours)
          allocation.start_time = Time.now.at_beginning_of_day + 7.hours
          allocation.end_time = Time.now.at_beginning_of_day + 9.hours
          allocation.course_class = other_allocation.course_class
          allocation.day = other_allocation.day
          allocation.should have(0).errors_on :start_time
          allocation.should have(0).errors_on :end_time
        end
      end
      context "should have error scheduling_conflict when" do
        it "start_time between another allocation's start_time and end_time" do
          other_allocation = Factory.create(:allocation, :start_time => Time.now.at_beginning_of_day + 10.hours, :end_time => Time.now.at_beginning_of_day + 12.hours)
          allocation.start_time = Time.now.at_beginning_of_day + 11.hours
          allocation.end_time = Time.now.at_beginning_of_day + 13.hours
          allocation.course_class = other_allocation.course_class
          allocation.day = other_allocation.day
          allocation.should have_error(:scheduling_conflict).on :start_time
          allocation.should have(0).errors_on :end_time
        end
        it "end_time between another allocation's start_time and end_time" do
          other_allocation = Factory.create(:allocation, :start_time => Time.now.at_beginning_of_day + 10.hours, :end_time => Time.now.at_beginning_of_day + 12.hours)
          allocation.start_time = Time.now.at_beginning_of_day + 9.hours
          allocation.end_time = Time.now.at_beginning_of_day + 11.hours
          allocation.course_class = other_allocation.course_class
          allocation.day = other_allocation.day
          allocation.should have_error(:scheduling_conflict).on :end_time
          allocation.should have(0).errors_on :start_time
        end
      end
    end
  end
end