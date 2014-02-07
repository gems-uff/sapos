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
    describe "email" do
      context "should be valid when" do
        it "email is not null" do
          user.email = "Username"
          user.should have(0).errors_on :email
        end
      end
      context "should have error blank when" do
        it "email is null" do
          user.email = nil
          user.should have_error(:blank).on :email
        end
      end
      context "should have error taken when" do
        it "email is already in use" do
          FactoryGirl.create(:user, :email => 'email@sapos.com')
          user.email = 'email@sapos.com'
          user.should have_error(:taken).on :email
        end
      end
    end
    describe "name" do
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
    describe "role" do
      context "should be valid when" do
        it "role is not null" do
          user.role = FactoryGirl.create(:role)
          user.should have(0).errors_on :role
        end
      end
      context "should have error blank when" do
        it "role is null" do
          user.role = nil
          user.should have_error(:blank).on :role
        end
      end
    end
  end
  describe "Methods" do
    describe "professor" do
      it "should return nil if there is no user with the same email" do
        user = FactoryGirl.create(:user, :email => 'noprofessoremail@sapos.com')
        user.professor.should == nil
      end
      it "should return an user if there is a user with the same email" do
        user = FactoryGirl.create(:user, :email => 'oldemail@sapos.com')
        professor = FactoryGirl.create(:professor, :email => user.email)
        user.professor.should == professor
      end
    end
  end
  describe "Callbacks" do
    describe "after_save" do
      describe "update_email" do
        it "should update professor email, if there is a professor with the old email" do
          user = FactoryGirl.create(:user, :email => 'oldemail@sapos.com')
          professor = FactoryGirl.create(:professor, :email => user.email)
          user.email = 'newemail@sapos.com'
          user.save 
          Professor.find(professor.id).email.should == 'newemail@sapos.com'
        end
      end
    end
  end
end