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
    describe "professor_id" do
      context "should be valid when" do
        it "don't exists another advisement for the same enrollment" do
          advisement.professor = Professor.new
          advisement.should have(0).errors_on :professor_id
        end
      end
      context "should have uniqueness error when" do
        it "already exists another advisement for the same enrollment" do
          advisement.professor = FactoryGirl.create(:professor)
          advisement.enrollment = FactoryGirl.create(:enrollment)
          FactoryGirl.create(:advisement, :professor => advisement.professor, :enrollment => advisement.enrollment)
          advisement.should have_error(:taken).on :professor_id
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
    describe "co_advisor_list" do
      it "should return the expected string" do
        professor1_name = "Leonardo"
        professor2_name = "Vanessa"
        professor1 = FactoryGirl.create(:professor, :name => professor1_name)
        professor2 = FactoryGirl.create(:professor, :name => professor2_name)
        advisement = FactoryGirl.create(:advisement)
        FactoryGirl.create(:advisement, :professor => professor1, :enrollment => advisement.enrollment, :main_advisor => false)
        FactoryGirl.create(:advisement, :professor => professor2, :enrollment => advisement.enrollment, :main_advisor => false)
        advisement.co_advisor_list.should eql("#{professor1_name} , #{professor2_name}")
      end
    end
    describe "active" do
      context "should return true when " do
        it "the enrollment does not have a dismissal" do
          advisement = FactoryGirl.create(:advisement)
          advisement.active.should be_true
        end
      end
      context "should return false when " do
        it "the enrollment have a dismissal" do
          advisement = FactoryGirl.create(:advisement)
          FactoryGirl.create(:dismissal, :enrollment => advisement.enrollment)
          advisement.active.should be_false
        end
      end
    end
    describe "co_advisor" do
      context "should return true when " do
        it "the enrollment have another advisement" do
          other_advisement = FactoryGirl.create(:advisement)
          FactoryGirl.create(:advisement, :enrollment => other_advisement.enrollment, :main_advisor => false)
          other_advisement.co_advisor.should be_true
        end
      end
      context "should return false when " do
        it "the enrollment does not have another advisement" do
          advisement = FactoryGirl.create(:advisement)
          advisement.co_advisor.should be_false
        end
      end
    end
    describe "enrollment_has_advisors" do
      context "should return true when " do
        it "the enrollment have one advisement" do
          advisement = FactoryGirl.create(:advisement)
          advisement.enrollment_has_advisors.should be_true
        end
      end
      context "should return false when " do
        it "the enrollment does not have any advisements" do
          advisement.enrollment = FactoryGirl.create(:enrollment)
          advisement.enrollment_has_advisors.should be_false
        end
      end
    end
  end
end