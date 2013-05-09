require "spec_helper"

describe Country do
  let(:country) { Country.new }
  subject { country }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          country.name = "Country name"
          country.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          country.name = nil
          country.should have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "Country name"
          FactoryGirl.create(:country, :name => name)
          country.name = name
          country.should have_error(:taken).on :name
        end
      end
    end
  end
end