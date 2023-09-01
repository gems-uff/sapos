# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# ToDo: Remember me
# ToDo: Login fail
# ToDo: Forgot password page
# ToDo: Confirmation page
# ToDo: Unlock page

RSpec.describe "Users features", type: :feature do
  before(:all) do
    @destroy_later = []
    @role_adm = FactoryBot.create :role_administrador
    @role_aluno = FactoryBot.create :role_aluno
    @role_professor = FactoryBot.create :role_professor
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @role_adm.delete
    @role_aluno.delete
    @role_professor.delete
  end

  it "sign admin in" do
    @destroy_later << create_confirmed_user(@role_adm)
    visit "/users/sign_in"
    within("#login_form") do
      fill_in "Email ou CPF", with: "user@ic.uff.br"
      fill_in "Senha", with: "A1b2c3d4!"
    end
    click_button "Login"
    expect(page).to have_content "Login feito com sucesso."
  end

  it "sign professor in by CPF" do
    @destroy_later << professor = Professor.create(name: "ana", cpf: "123.456.789-10")
    @destroy_later << user = create_confirmed_user(@role_professor)
    professor.user = user
    professor.save!

    visit "/users/sign_in"
    within("#login_form") do
      fill_in "Email ou CPF", with: "123.456.789-10"
      fill_in "Senha", with: "A1b2c3d4!"
    end
    click_button "Login"
    expect(page).to have_content "Login feito com sucesso."
  end

  it "sign student in by CPF" do
    @destroy_later << student = Student.create(name: "ana", cpf: "123.456.789-10")
    @destroy_later << user = create_confirmed_user(@role_aluno)
    student.user = user
    student.save!

    visit "/users/sign_in"
    within("#login_form") do
      fill_in "Email ou CPF", with: "123.456.789-10"
      fill_in "Senha", with: "A1b2c3d4!"
    end
    click_button "Login"
    expect(page).to have_content "Login feito com sucesso."
  end
end
