# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# ToDo: advisement_authorizarion

RSpec.describe "DismissalReason features", type: :feature do
  let(:url_path) { "/dismissal_reasons" }
  let(:plural_name) { "dismissal_reasons" }
  let(:model) { DismissalReason }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user([@role_adm])
    @destroy_all << @record = FactoryBot.create(:dismissal_reason, name: "Desistência", thesis_judgement: "--")
    @destroy_all << FactoryBot.create(:dismissal_reason, name: "Reprovado", thesis_judgement: "Reprovado")
    @destroy_all << FactoryBot.create(:dismissal_reason, name: "Titulação", thesis_judgement: "Aprovado")
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @destroy_all.each(&:delete)
    @destroy_all.clear
    UserRole.delete_all
  end

  describe "view list page" do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should show table" do
      expect(page).to have_content "Razões de Desligamento"
      expect(page.all("tr th").map(&:text)).to eq [
        "Nome", "Descrição", "Mostrar Orientador no Histórico", "Julgamento da Tese", ""
      ]
    end

    it "should sort the list by name, asc" do
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Desistência", "Reprovado", "Titulação"]
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
      expect(page).to have_content "Adicionar Razão de Desligamento"
      within("#as_#{plural_name}-create--form") do
        fill_in "Nome", with: "Prazo"
        find(:select, "record_thesis_judgement_").find(:option, text: "--").select_option
      end
      click_button "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "Prazo")
      expect(page).to have_css("tr:nth-child(1) td.thesis_judgement-column", text: "--")

      # Remove inserted record
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Prazo", "Desistência", "Reprovado", "Titulação"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Desistência", "Reprovado", "Titulação"]
    end

    it "should have a selection for thesis_judgement options" do
      expect(page.all("select#record_thesis_judgement_ option").map(&:text)).to eq ["Selecione uma opção", "Aprovado", "Reprovado", "--"]
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
        fill_in "Nome", with: "Teste"
        find(:select, "record_thesis_judgement_#{@record.id}").find(:option, text: "Aprovado").select_option
      end
      click_button "Atualizar"
      expect(page).to have_css("td.name-column", text: "Teste")
      expect(page).to have_css("td.thesis_judgement-column", text: "Aprovado")
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by name" do
      fill_in "search", with: "Repro"
      sleep(0.8)
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Reprovado"]
    end
  end
end
