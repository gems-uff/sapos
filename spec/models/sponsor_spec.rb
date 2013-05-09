require "spec_helper"

describe Sponsor do
  let(:sponsor) { Sponsor.new }
  subject { sponsor }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          sponsor.name = "Sponsor name"
          sponsor.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          sponsor.name = nil
          sponsor.should have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "Sponsor name"
          FactoryGirl.create(:sponsor, :name => name)
          sponsor.name = name
          sponsor.should have_error(:taken).on :name
        end
      end
    end
  end
end