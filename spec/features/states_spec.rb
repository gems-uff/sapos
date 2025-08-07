# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "States features", type: :feature do
  let(:url_path) { "/states" }
  let(:plural_name) { "states" }
  let(:model) { State }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user(@role_adm)

    @destroy_all << @country1 = FactoryBot.create(:country, name: "Brasil", nationality: "brasileiro(a)")
    @destroy_all << @country2 = FactoryBot.create(:country, name: "Portugal", nationality: "português(a)")
    @destroy_all << @country3 = FactoryBot.create(:country, name: "Estados Unidos", nationality: "norte-americano(a)")

    @destroy_all << FactoryBot.create(:state, country: @country1, name: "Rio de Janeiro", code: "RJ")
    @destroy_all << @record = FactoryBot.create(:state, country: @country1, name: "São Paulo", code: "SP")
    @destroy_all << FactoryBot.create(:state, country: @country1, name: "Acre", code: "AC")
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
      expect(page).to have_content "Estados"
      expect(page.all("tr th").map(&:text)).to eq [
        "Nome", "Sigla", "País", ""
      ]
    end

    it "should sort the list by name, asc" do
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Acre", "Rio de Janeiro", "São Paulo"]
    end
  end

  describe "insert page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Adicionar"
    end

    it "should be able to insert and remove record" do
      # Insert record
      expect(page).to have_content "Adicionar Estado"
      within("#as_#{plural_name}-create--form") do
        find(:select, "record_country_").find(:option, text: @country1.name).select_option
        fill_in "Nome", with: "Minas Gerais"
        fill_in "Sigla", with: "MG"
      end
      click_button_and_wait "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "Minas Gerais")

      # Remove inserted record
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Minas Gerais", "Acre", "Rio de Janeiro", "São Paulo"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Acre", "Rio de Janeiro", "São Paulo"]
    end

    it "should have a selection for country options" do
      expect(page.all("select#record_country_ option").map(&:text)).to eq ["Selecione uma opção", "Brasil", "Estados Unidos", "Portugal"]
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
      end
      click_button_and_wait "Atualizar"
      expect(page).to have_css("td.name-column", text: "Teste")
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Buscar"
    end

    it "should be able to search by name" do
      fill_in "search", with: "Acr"
      sleep(0.8)
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Acre"]
    end
  end
end
