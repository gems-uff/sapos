require 'spec_helper'

describe PhaseCompletion do
  let(:phase_completion) { PhaseCompletion.new }
  subject { deferral }
  describe "Validations" do
    describe "enrollment" do
      context "should be valid when" do
        it "enrollment_id is not null" do
          phase_completion.enrollment_id = 1
          phase_completion.should have(0).errors_on :enrollment_id
        end
      end
      context "should have error blank when" do
        it "enrollment_id is null" do
          phase_completion.enrollment_id = nil
          phase_completion.should have_error(:blank).on :enrollment_id
        end
      end
    end
    describe "phase_id" do
      context "should be valid when" do
        it "phase_id is not null" do
          PhaseCompletion.destroy_all
          phase_completion.phase_id = 1
          phase_completion.should have(0).errors_on :phase_id
        end
      end
      context "should have error blank when" do
        it "phase_id is null" do
          phase_completion.phase_id = nil
          phase_completion.should have_error(:blank).on :phase_id
        end
      end
    end

    describe "unique (phase_id, enrollment_id)" do
      context "should be valid when" do
        it "(phase_id, enrollment_id) is unique" do
          PhaseCompletion.destroy_all
          phase_completion.phase_id = 1
          phase_completion.enrollment_id = 1
          phase_completion.should have(0).errors_on :phase_id
        end
      end
      context "should have error taken when" do
        it "(phase_id, enrollment_id) is not unique" do
          PhaseCompletion.destroy_all
          FactoryGirl.create(:phase_completion, :phase_id => 1, :enrollment_id => 1)
          
          phase_completion.phase_id = 1
          phase_completion.enrollment_id = 1
          phase_completion.should have_error(:taken).on :phase_id
        end
      end
    end
  end
end
