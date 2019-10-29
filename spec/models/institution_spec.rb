# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Institution do
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists :major }
  it { should restrict_destroy_when_exists :professor }

  let(:institution) { Institution.new }
  subject { institution }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          institution.name = "Institution name"
          expect(institution).to have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          institution.name = nil
          expect(institution).to have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "Institution name"
          FactoryGirl.create(:institution, :name => name)
          institution.name = name
          expect(institution).to have_error(:taken).on :name
        end
      end
    end
  end
end
