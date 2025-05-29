# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "DeferralTypes features", type: :feature do
  let(:url_path) { "/deferral_types" }
  let(:plural_name) { "deferral_types" }
  let(:model) { DeferralType }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user([@role_adm])
    @destroy_all << @phase1 = FactoryBot.create(:phase, name: "Artigo A1")
    @destroy_all << @phase2 = FactoryBot.create(:phase, name: "Pedido de Banca")
    @destroy_all << @phase3 = FactoryBot.create(:phase, name: "Exame de Qualificação")

    @destroy_all << FactoryBot.create(:deferral_type, name: "Extraordinária", phase: @phase2)
    @destroy_all << @record = FactoryBot.create(:deferral_type, name: "Regular", phase: @phase2)
    @destroy_all << FactoryBot.create(:deferral_type, name: "Final", phase: @phase2)
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
      expect(page).to have_content "Etapas"
      expect(page.all("tr th").map(&:text)).to eq [
        "Nome", "Descrição", "Duração(períodos)", "Duração(meses)", "Duração(dias)", "Etapa", ""
      ]
    end

    it "should sort the list by name, asc" do
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Extraordinária", "Final", "Regular"]
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
      expect(page).to have_content "Adicionar Tipo de Prorrogação"
      within("#as_#{plural_name}-create--form") do
        fill_in "Nome", with: "EQ"
        fill_in "Duração(períodos)", with: "1"
        find(:select, "record_phase_").find(:option, text: "Exame de Qualificação").select_option
      end
      click_button "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "EQ")

      # Remove inserted record
      expect(page.all("tr td.name-column").map(&:text)).to eq ["EQ", "Extraordinária", "Final", "Regular"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Extraordinária", "Final", "Regular"]
    end

    it "should have a selection for phase options" do
      expect(page.all("select#record_phase_ option").map(&:text)).to eq ["Selecione uma opção", "Artigo A1", "Exame de Qualificação", "Pedido de Banca"]
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
      fill_in "search", with: "Fin"
      sleep(0.8)
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Final"]
    end
  end
end
