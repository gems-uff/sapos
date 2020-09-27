# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Level do
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists :enrollment }
  it { should destroy_dependent :advisement_authorization }
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
          expect(level).to have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          level.name = nil
          expect(level).to have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "Level name"
          FactoryBot.create(:level, :name => name)
          level.name = name
          expect(level).to have_error(:taken).on :name
        end
      end
    end
    describe "default_duration" do
      context "should be valid when" do
        it "default_duration is not null" do
          level.default_duration = 48
          expect(level).to have(0).errors_on :default_duration
        end
      end
      context "should have error blank when" do
        it "default_duration is null" do
          level.default_duration = nil
          expect(level).to have_error(:blank).on :default_duration
        end
      end
    end
  end
end
