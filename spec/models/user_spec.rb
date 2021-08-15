# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"


describe User do
  before :all do
    FactoryBot.create :role_administrador
    FactoryBot.create :role_aluno
    FactoryBot.create :role_professor
  end
  let(:user) { User.new }
  subject { user }
  describe "Validations" do
    describe "email" do
      context "should be valid when" do
        it "email is not null" do
          user.email = "Username"
          expect(user).to have(0).errors_on :email
        end
      end
      context "should have error blank when" do
        it "email is null" do
          user.email = nil
          expect(user).to have_error(:blank).on :email
        end
      end
      context "should have error taken when" do
        it "email is already in use" do
          FactoryBot.create(:user, :email => 'email@sapos.com')
          user.email = 'email@sapos.com'
          expect(user).to have_error(:taken).on :email
        end
      end
    end
    describe "name" do
      context "should be valid when" do
        it "name is not null and is unique" do
          user.name = "Username"
          expect(user).to have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          user.name = nil
          expect(user).to have_error(:blank).on :name
        end
      end
    end
    describe "role" do
      context "should be valid when" do
        it "role is not null" do
          user.role = FactoryBot.create(:role)
          expect(user).to have(0).errors_on :role
        end
      end
      context "should have error blank when" do
        it "role is null" do
          user.role = nil
          expect(user).to have_error(:blank).on :role
        end
      end
    end
    describe "professor" do
      context "should be valid when" do
        it "professor is null" do
          user.professor = nil
          expect(user).to have(0).errors_on :professor
        end
        it "professor is not null and role is professor" do
          user.role_id = Role::ROLE_PROFESSOR
          user.professor = FactoryBot.create(:professor)
          expect(user).to have(0).errors_on :professor
        end
        it "professor is changed to another professor that is not associated with any users" do
          user.role_id = Role::ROLE_PROFESSOR
          user.professor = FactoryBot.create(:professor)
          user.save(validate: false)
          user.professor = FactoryBot.create(:professor)
          expect(user).to have(0).errors_on :professor
        end
      end
      context "should have error selected_role_was_not_professor when" do
        it "professor is not null and role is not professor" do
          user.role_id = Role::ROLE_ALUNO
          user.professor = FactoryBot.create(:professor)
          expect(user).to have_error(:selected_role_was_not_professor).on :professor
        end
      end
      #context "should have error selected_professor_is_already_linked_to_another_user when" do
        # I could not reproduce this validation outside active scaffold
      #end
    end
    describe "student" do
      context "should be valid when" do
        it "student is null" do
          user.student = nil
          expect(user).to have(0).errors_on :student
        end
        it "student is not null and role is student" do
          user.role_id = Role::ROLE_ALUNO
          user.student = FactoryBot.create(:student)
          expect(user).to have(0).errors_on :student
        end
        it "student is changed to another student that is not associated with any users" do
          user.role_id = Role::ROLE_ALUNO
          user.student = FactoryBot.create(:student)
          user.save(validate: false)
          user.student = FactoryBot.create(:student)
          expect(user).to have(0).errors_on :student
        end
      end
      context "should have error selected_role_was_not_student when" do
        it "student is not null and role is not student" do
          user.role_id = Role::ROLE_PROFESSOR
          user.student = FactoryBot.create(:student)
          expect(user).to have_error(:selected_role_was_not_student).on :student
        end
      end
      #context "should have error selected_student_is_already_linked_to_another_user when" do
        # I could not reproduce this validation outside active scaffold
      #end
    end
  end
end
