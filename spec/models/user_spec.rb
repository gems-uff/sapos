# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe User do
  before :all do
    FactoryGirl.create :role_administrador
  end
  let(:user) { User.new }
  subject { user }
  describe "Validations" do
    describe "enrollment" do
      context "should be valid when" do
        it "name is not null and is unique" do
          user.name = "Username"
          user.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          user.name = nil
          user.should have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "Username"
          FactoryGirl.create(:user, :name => name)
          user.name = name
          user.should have_error(:taken).on :name
        end
      end
    end
  end
end