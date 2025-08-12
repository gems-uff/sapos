# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Users features", type: :feature do
  let(:url_path) { "/users" }
  let(:plural_name) { "users" }
  let(:model) { User }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << FactoryBot.create(:role_desconhecido)
    @destroy_all << FactoryBot.create(:role_coordenacao)
    @destroy_all << FactoryBot.create(:role_secretaria)
    @destroy_all << FactoryBot.create(:role_professor)
    @destroy_all << FactoryBot.create(:role_aluno)
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << FactoryBot.create(:role_suporte)

    @destroy_all << @user = create_confirmed_user(@role_adm)
    @destroy_all << FactoryBot.create(:user, email: "user3@ic.uff.br", name: "carol")
    @destroy_all << @record = FactoryBot.create(:user, email: "user2@ic.uff.br", name: "bia")
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @destroy_all.each(&:delete)
    @destroy_all.clear
  end

  describe "view list page" do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should show table" do
      expect(page).to have_content "Usuários"
      expect(page.all("tr th").map(&:text)).to eq [
        "Email", "Nome do usuário", "Papel", ""
      ]
    end

    it "should not have a sorting -- show in id order" do
      expect(page.all("tr td.name-column").map(&:text)).to eq ["ana", "carol", "bia"]
    end
  end

  describe "insert page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Adicionar"
    end

    it "should be able to insert and remove record" do
      # Insert record
      expect(page).to have_content "Adicionar Usuário"
      within("#as_#{plural_name}-create--form") do
        find(:select, "record_role_").find(:option, text: "Administrador").select_option
        fill_in "Email", with: "user4@ic.uff.br"
        fill_in "Nome do usuário", with: "dani"
      end
      click_button_and_wait "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "dani")

      # Remove inserted record
      expect(page.all("tr td.name-column").map(&:text)).to eq ["dani", "ana", "carol", "bia"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.name-column").map(&:text)).to eq ["ana", "carol", "bia"]
    end

    it "should have a selection for role options" do
      expect(page.all("select#record_role_ option").map(&:text)).to eq ["Selecione uma opção", "Administrador", "Aluno", "Coordenação", "Desconhecido", "Professor", "Secretaria", "Suporte"]
    end

    it "should have a record_select widget for professor" do
      expect_to_have_record_select(page, "professor_", "professors")
    end

    it "should have a record_select widget for student" do
      expect_to_have_record_select(page, "student_", "students")
    end
  end

  describe "edit page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-edit-#{@record.id}-link").click
    end

    it "should be able to edit student" do
      within(".as_form") do
        fill_in "Nome do usuário", with: "Teste"
      end
      click_button_and_wait "Atualizar"
      expect(page).to have_css("td.name-column", text: "Teste")
      @record.name = "bia"
      @record.save!
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by name" do
      fill_in "search", with: "car"
      sleep(0.8)
      expect(page.all("tr td.name-column").map(&:text)).to eq ["carol"]
    end
  end
end
