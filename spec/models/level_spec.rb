# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Level do
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists :enrollment }
  it { should restrict_destroy_when_exists :advisement_authorization }
  it { should restrict_destroy_when_exists :major }
  it { should restrict_destroy_when_exists :phase_duration }
  it { should restrict_destroy_when_exists :scholarship }
  
  
  let(:level) { Level.new }
  subject { level }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          level.name = "Level name"
          level.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          level.name = nil
          level.should have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "Level name"
          FactoryGirl.create(:level, :name => name)
          level.name = name
          level.should have_error(:taken).on :name
        end
      end
    end
  end
end