# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe User, type: :model do
  it { should have_one(:professor) }
  it { should have_one(:student).dependent(:nullify) }
  it { should have_many(:enrollment_request_comments).dependent(:destroy) }
  it { should have_many(:roles).through(:user_roles) }
  it { should have_many(:user_roles).dependent(:destroy) }

  before(:all) do
    @destroy_later = []
    @role_adm = FactoryBot.create :role_administrador
    @role_aluno = FactoryBot.create :role_aluno
    @role_professor = FactoryBot.create :role_professor
    @user_role = FactoryBot.create(:user_role, user: User.create!(email: "temp@ic.uff.br", name: "Temp"), role: @role_aluno)
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @user_role.role.delete unless [@role_adm, @role_aluno, @role_professor].include?(@user_role.role)
    @user_role.user.delete if @user_role.user
    @role_adm.delete
    @role_aluno.delete
    @role_professor.delete
    @user_role.delete
    (Role.all - [@role_adm, @role_aluno, @role_professor]).each(&:delete)
  end
  let(:user) do
    User.new(
      actual_role: @role_aluno,
      email: "user@ic.uff.br",
      name: "ana",
    )
  end
  subject { user }
  describe "Validations" do
    it { should be_valid }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }

    describe "professor" do
      context "should be valid when" do
        it "professor is null" do
          user.professor = nil
          expect(user).to have(0).errors_on :professor
        end
        it "professor is not null and role is professor" do
          user.roles << @role_professor unless user.roles.include?(@role_professor)
          user.actual_role = @role_professor.id
          user.professor = @professor
          @destroy_later << user.professor = FactoryBot.create(:professor)
          user.save!
          expect(user).to have(0).errors_on :professor
        end
        it "professor is changed to another professor that is not associated with any users" do
          user.roles << @role_professor unless user.roles.include?(@role_professor)
          user.actual_role = @role_professor.id
          @destroy_later << user.professor = FactoryBot.create(:professor)
          user.save(validate: false)
          @destroy_later << user
          @destroy_later << user.professor = FactoryBot.create(:professor)
          expect(user).to have(0).errors_on :professor
        end
      end
      context "should have error selected_role_was_not_professor when" do
        it "professor is not null and role is not professor" do
          user.actual_role = Role::ROLE_ALUNO
          @destroy_later << user.professor = FactoryBot.create(:professor)
          expect(user).to have_error(:selected_role_was_not_professor).on :professor
        end
      end
      # context "should have error selected_professor_is_already_linked_to_another_user when" do
      # I could not reproduce this validation outside active scaffold
      # end
    end
    describe "student" do
      context "should be valid when" do
        it "student is null" do
          user.student = nil
          expect(user).to have(0).errors_on :student
        end
        it "student is not null and role is student" do
          user.roles << @role_aluno unless user.roles.include?(@role_aluno)
          user.actual_role = @role_aluno.id
          @destroy_later << user.student = FactoryBot.create(:student)
          user.save!
          expect(user).to have(0).errors_on :student
        end
        it "student is changed to another student that is not associated with any users" do
          user.roles << @role_aluno unless user.roles.include?(@role_aluno)
          user.actual_role = @role_aluno.id
          @destroy_later << user.student = FactoryBot.create(:student)
          user.save(validate: false)
          @destroy_later << user
          @destroy_later << user.student = FactoryBot.create(:student)
          expect(user).to have(0).errors_on :student
        end
      end
      context "should have error selected_role_was_not_student when" do
        it "student is not null and role is not student" do
          user.actual_role = Role::ROLE_PROFESSOR
          @destroy_later << user.student = FactoryBot.create(:student)
          expect(user).to have_error(:selected_role_was_not_student).on :student
        end
      end
      # context "should have error selected_student_is_already_linked_to_another_user when" do
      # I could not reproduce this validation outside active scaffold
      # end
    end
  end
end
