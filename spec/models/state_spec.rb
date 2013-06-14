# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe State do
  let(:state) { State.new }
  subject { state }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          state.name = "State name"
          state.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          state.name = nil
          state.should have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "State name"
          FactoryGirl.create(:state, :name => name)
          state.name = name
          state.should have_error(:taken).on :name
        end
      end
    end
    describe "code" do
      context "should be valid when" do
        it "code is not null and is not taken" do
          state.code = "State code"
          state.should have(0).errors_on :code
        end
      end
      context "should have error blank when" do
        it "code is null" do
          state.code = nil
          state.should have_error(:blank).on :code
        end
      end
      context "should have error taken when" do
        it "code is already in use" do
          code = "State code"
          FactoryGirl.create(:state, :code => code)
          state.code = code
          state.should have_error(:taken).on :code
        end
      end
    end
    describe "country" do
      context "should be valid when" do
        it "country is not null" do
          state.country = Country.new
          state.should have(0).errors_on :country
        end
      end
      context "should have error blank when" do
        it "country is null" do
          state.country = nil
          state.should have_error(:blank).on :country
        end
      end
    end
  end
end