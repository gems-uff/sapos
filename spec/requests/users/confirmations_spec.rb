# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Users::ConfirmationsController", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create :role_administrador
    @role_aluno = FactoryBot.create :role_aluno
    @role_professor = FactoryBot.create :role_professor
  end

  describe "GET /users/confirmation" do
    it "confirms a pending email change of the user" do
      user = create_confirmed_user([@role_adm], "old@ic.uff.br")
      user.update!(email: "new@ic.uff.br")
      expect(user.reload.unconfirmed_email).to eq("new@ic.uff.br")

      get user_confirmation_path(confirmation_token: user.confirmation_token)

      expect(user.reload.email).to eq("new@ic.uff.br")
      expect(user.unconfirmed_email).to be_nil
    end

    it "propagates a confirmed email change to the student of the user" do
      student = Student.create!(name: "ana", cpf: "123.456.789-10",
        email: "old@ic.uff.br")
      user = create_confirmed_user([@role_aluno], "old@ic.uff.br",
        student: student)
      user.update!(email: "new@ic.uff.br")

      get user_confirmation_path(confirmation_token: user.confirmation_token)

      expect(student.reload.email).to eq("new@ic.uff.br")
    end

    it "propagates a confirmed email change to the professor of the user" do
      professor = Professor.create!(name: "ana", cpf: "123.456.789-10",
        email: "old@ic.uff.br")
      user = create_confirmed_user([@role_professor], "old@ic.uff.br",
        professor: professor)
      user.update!(email: "new@ic.uff.br")

      get user_confirmation_path(confirmation_token: user.confirmation_token)

      expect(professor.reload.email).to eq("new@ic.uff.br")
    end

    it "keeps the email of the student when the confirmation does not change the email" do
      student = Student.create!(name: "ana", cpf: "123.456.789-10",
        email: "student@ic.uff.br")
      user = User.create!(
        roles: [@role_aluno], name: "ana", email: "user@ic.uff.br",
        password: "A1b2c3d4!", student: student
      )
      expect(user.reload.confirmed_at).to be_nil

      get user_confirmation_path(confirmation_token: user.confirmation_token)

      expect(user.reload.confirmed_at).to_not be_nil
      expect(student.reload.email).to eq("student@ic.uff.br")
    end
  end
end
