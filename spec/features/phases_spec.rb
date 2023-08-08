# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Phases features", type: :feature do
  let(:url_path) { "/phases" }
  let(:plural_name) { "phases" }
  let(:model) { Phase }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user(@role_adm)
    @destroy_all << @record = FactoryBot.create(:phase, name: "Artigo A1")
    @destroy_all << FactoryBot.create(:phase, name: "Pedido de Banca")
    @destroy_all << FactoryBot.create(:phase, name: "Exame de Qualificação")
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
      expect(page).to have_content "Etapas"
      expect(page.all("tr th").map(&:text)).to eq [
        "Nome", "Descrição", "Exame de Línguas", "Prorrogar com Trancamentos", ""
      ]
    end

    it "should sort the list by name, asc" do
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Artigo A1", "Exame de Qualificação", "Pedido de Banca"]
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
      expect(page).to have_content "Adicionar Etapa"
      within("#as_#{plural_name}-create--form") do
        fill_in "Nome", with: "Prova de Inglês"
      end
      click_button "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "Prova de Inglês")

      # Remove inserted record
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Prova de Inglês", "Artigo A1", "Exame de Qualificação", "Pedido de Banca"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Artigo A1", "Exame de Qualificação", "Pedido de Banca"]
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
        fill_in "Descrição", with: "Teste"
      end
      click_button "Atualizar"
      expect(page).to have_css("td.description-column", text: "Teste")
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by name" do
      fill_in "search", with: "Pedido"
      sleep(0.8)
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Pedido de Banca"]
    end
  end
end
