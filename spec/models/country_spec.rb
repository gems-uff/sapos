# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Country do
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists :state }

  let(:country) { Country.new }
  subject { country }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          country.name = "Country name"
          expect(country).to have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          country.name = nil
          expect(country).to have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "Country name"
          FactoryGirl.create(:country, :name => name)
          country.name = name
          expect(country).to have_error(:taken).on :name
        end
      end
    end
  end
end
