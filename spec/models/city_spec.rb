# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe City do
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists(:student).with_fk :city_id }
  it { should restrict_destroy_when_exists(:student).with_fk :birth_city_id }
  it { should restrict_destroy_when_exists(:professor).with_fk :city_id }

  let(:city) { City.new }
  subject { city }
  describe "Validations" do
    describe "state" do
      context "should be valid when" do
        it "state is not null" do
          city.state = State.new
          city.should have(0).errors_on :state
        end
      end
      context "should have error blank when" do
        it "state is null" do
          city.state = nil
          city.should have_error(:blank).on :state
        end
      end
    end
    describe "name" do
      context "should be valid when" do
        it "name is not null" do
          city.name = "City name"
          city.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          city.name = nil
          city.should have_error(:blank).on :name
        end
      end
    end
  end
end