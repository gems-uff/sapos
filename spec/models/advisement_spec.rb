require "spec_helper"

describe Advisement do
  let(:advisement) { Advisement.new }
  subject { advisement }
  describe "Validations" do
    describe "enrollment" do
      context "should be valid when" do
        it "enrollment is not null" do
          advisement.enrollment = Enrollment.new
          advisement.should have(0).errors_on :enrollment
        end
      end
      context "should have error blank when" do
        it "enrollment is null" do
          advisement.enrollment = nil
          advisement.should have_error(:blank).on :enrollment
        end
      end
    end
    describe "professor" do
      context "should be valid when" do
        it "professor is not null" do
          advisement.professor = Professor.new
          advisement.should have(0).errors_on :professor
        end
      end
      context "should have error blank when" do
        it "professor is null" do
          advisement.professor = nil
          advisement.should have_error(:blank).on :professor
        end
      end
    end
    describe "main_advisor" do
      context "should be valid when" do
        it "have other advisor" do
          advisement.stub!(:enrollment_has_advisors).and_return(true)
          advisement.main_advisor = nil
          advisement.should have(0).errors_on :main_advisor
        end
        it "does not have other advisor and main_advisor is true" do
          advisement.stub!(:enrollment_has_advisors).and_return(false)
          advisement.main_advisor = true
          advisement.should have(0).errors_on :main_advisor
        end
      end
      context "should have error blank when" do
        it "does not have other advisor and main_advisor is false" do
          advisement.stub!(:enrollment_has_advisors).and_return(false)
          advisement.main_advisor = false
          advisement.should have_error(:blank).on :main_advisor
        end
      end
      context "should have uniqueness error when" do
        it "main_advisor is true and another advisement with main_advisor of same enrollment exists" do
          advisement.main_advisor = true
          advisement.enrollment = FactoryGirl.create(:enrollment)
          FactoryGirl.create(:advisement, :enrollment => advisement.enrollment)
          advisement.should have_error(:taken).on :main_advisor
        end
      end
    end
  end
  describe "Methods" do
    describe "to_label" do
      it "should return the expected string" do
        enrollment_number = "123"
        professor_name = "professor"
        advisement.enrollment = Enrollment.new(:enrollment_number => enrollment_number)
        advisement.professor = Professor.new(:name => professor_name)
        advisement.to_label.should eql("#{enrollment_number} - #{professor_name}")
      end
    end
  end
end