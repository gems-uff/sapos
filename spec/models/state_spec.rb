# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe State do
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists(:student).with_fk :birth_state_id }
  it { should restrict_destroy_when_exists(:city).with_fk :state_id }

  let(:state) { State.new }
  subject { state }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          state.name = "State name"
          expect(state).to have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          state.name = nil
          expect(state).to have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "State name"
          FactoryBot.create(:state, :name => name)
          state.name = name
          expect(state).to have_error(:taken).on :name
        end
      end
    end
    describe "code" do
      context "should be valid when" do
        it "code is not null and is not taken" do
          state.code = "State code"
          expect(state).to have(0).errors_on :code
        end
      end
      context "should have error blank when" do
        it "code is null" do
          state.code = nil
          expect(state).to have_error(:blank).on :code
        end
      end
      context "should have error taken when" do
        it "code is already in use" do
          code = "State code"
          FactoryBot.create(:state, :code => code)
          state.code = code
          expect(state).to have_error(:taken).on :code
        end
      end
    end
    describe "country" do
      context "should be valid when" do
        it "country is not null" do
          state.country = Country.new
          expect(state).to have(0).errors_on :country
        end
      end
      context "should have error blank when" do
        it "country is null" do
          state.country = nil
          expect(state).to have_error(:blank).on :country
        end
      end
    end
  end
end
