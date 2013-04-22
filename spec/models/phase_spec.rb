require "spec_helper"

describe Phase do
  let(:phase) { Phase.new }
  subject { phase }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          phase.name = "Phase name"
          phase.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          phase.name = nil
          phase.should have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "Phase name"
          FactoryGirl.create(:phase, :name => name)
          phase.name = name
          phase.should have_error(:taken).on :name
        end
      end
    end
  end
end