# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Sponsor do
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists :scholarship }
  
  let(:sponsor) { Sponsor.new }
  subject { sponsor }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          sponsor.name = "Sponsor name"
          expect(sponsor).to have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          sponsor.name = nil
          expect(sponsor).to have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "Sponsor name"
          FactoryGirl.create(:sponsor, :name => name)
          sponsor.name = name
          expect(sponsor).to have_error(:taken).on :name
        end
      end
    end
  end
end
