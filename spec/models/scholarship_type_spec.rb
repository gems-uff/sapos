require "spec_helper"

describe ScholarshipType do
  let(:scholarship_type) { ScholarshipType.new }
  subject { scholarship_type }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          scholarship_type.name = "ScholarshipType name"
          scholarship_type.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          scholarship_type.name = nil
          scholarship_type.should have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "ScholarshipType name"
          FactoryGirl.create(:scholarship_type, :name => name)
          scholarship_type.name = name
          scholarship_type.should have_error(:taken).on :name
        end
      end
    end
  end
end