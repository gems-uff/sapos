require "spec_helper"

describe Institution do
  let(:institution) { Institution.new }
  subject { institution }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          institution.name = "Institution name"
          institution.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          institution.name = nil
          institution.should have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "Institution name"
          FactoryGirl.create(:institution, :name => name)
          institution.name = name
          institution.should have_error(:taken).on :name
        end
      end
    end
  end
end