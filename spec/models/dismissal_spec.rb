require "spec_helper"

describe Dismissal do
  let(:dismissal) { Dismissal.new }
  subject { dismissal }
  describe "Validations" do
    describe "enrollment" do
      context "should be valid when" do
        it "enrollment is not null" do
          dismissal.enrollment = Enrollment.new
          dismissal.should have(0).errors_on :enrollment
        end
      end
      context "should have error blank when" do
        it "enrollment is null" do
          dismissal.enrollment = nil
          dismissal.should have_error(:blank).on :enrollment
        end
      end
    end
    describe "dismissal_reason" do
      context "should be valid when" do
        it "dismissal_reason is not null" do
          dismissal.dismissal_reason = DismissalReason.new
          dismissal.should have(0).errors_on :dismissal_reason
        end
      end
      context "should have error blank when" do
        it "dismissal_reason is null" do
          dismissal.dismissal_reason = nil
          dismissal.should have_error(:blank).on :dismissal_reason
        end
      end
    end
    describe "date" do
      context "should be valid when" do
        it "date is not null" do
          dismissal.date = Date.today
          dismissal.should have(0).errors_on :date
        end
      end
      context "should have error blank when" do
        it "date is null" do
          dismissal.date = nil
          dismissal.should have_error(:blank).on :date
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        dismissal_date = "#{Date.today}"
        dismissal.date = dismissal_date
        dismissal.to_label.should eql(dismissal_date)
      end
    end
  end
end