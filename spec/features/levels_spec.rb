# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# ToDo: advisement_authorizarion

RSpec.describe "Level features", type: :feature do
  let(:url_path) { "/levels" }
  let(:plural_name) { "levels" }
  let(:model) { Level }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user([@role_adm])
    @destroy_all << @record = FactoryBot.create(:level, name: "Mestrado", default_duration: 24)
    @destroy_all << FactoryBot.create(:level, name: "Doutorado", default_duration: 48)
    @destroy_all << FactoryBot.create(:level, name: "Especialização", default_duration: 0)
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
      expect(page).to have_content "Níveis"
      expect(page.all("tr th").map(&:text)).to eq [
        "Nome", "Nome completo do curso", "Duração padrão (meses)", "Credenciamentos", ""
      ]
    end

    it "should sort the list by name, asc" do
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Doutorado", "Especialização", "Mestrado"]
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
      expect(page).to have_content "Adicionar Nível"
      within("#as_#{plural_name}-create--form") do
        fill_in "Nome", with: "Graduação"
        fill_in "Duração padrão (meses)", with: "48"
      end
      click_button "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "Graduação")
      expect(page).to have_css("tr:nth-child(1) td.default_duration-column", text: "48")

      # Remove inserted record
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Graduação", "Doutorado", "Especialização", "Mestrado"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Doutorado", "Especialização", "Mestrado"]
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
        fill_in "Duração padrão (meses)", with: "12"
      end
      click_button "Atualizar"
      expect(page).to have_css("td.name-column", text: "Teste")
      expect(page).to have_css("td.default_duration-column", text: "12")
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by name" do
      fill_in "search", with: "Especia"
      sleep(0.8)
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Especialização"]
    end
  end
end
