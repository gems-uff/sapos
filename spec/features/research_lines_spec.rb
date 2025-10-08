# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "ResearchLines features", type: :feature do
  let(:url_path) { "/research_lines" }
  let(:plural_name) { "research_lines" }
  let(:model) { ResearchLine }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user([@role_adm])

    @destroy_all << @research_area = FactoryBot.create(:research_area, name: "Ciência da Computação", code: "CC")
    @destroy_all << @research_area1 = FactoryBot.create(:research_area, name: "Sistemas de Informação", code: "SI")

    @destroy_all << FactoryBot.create(:research_line, name: "Ciência de Dados", code: "CD", research_area: @research_area)
    @destroy_all << @record = FactoryBot.create(:research_line, name: "Engenharia de Software", code: "ES", research_area: @research_area)
    @destroy_all << FactoryBot.create(:research_line, name: "Desenvolvimento Web", code: "DW", research_area: @research_area1)
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @destroy_all.reverse_each(&:delete)
    @destroy_all.clear
    UserRole.delete_all
  end

  describe "view list page" do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should show table" do
      expect(page).to have_content "Linhas de Pesquisa"
      expect(page.all("tr th").map(&:text)).to eq [
        "Nome", "Código", "Área de Pesquisa", "Linha de Pesquisa Ativa", ""
      ]
    end

    it "should sort the list by name, asc" do
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Ciência de Dados", "Desenvolvimento Web", "Engenharia de Software"]
    end
  end

  describe "insert page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Adicionar"
    end

    it "should be able to insert and remove record" do
      expect(page).to have_content "Adicionar Linha de Pesquisa"
      fill_record_select("research_area_", "research_areas", "")
      within("#as_#{plural_name}-create--form") do
        fill_in "Nome", with: "Inteligência Artificial"
        fill_in "Código", with: "IA"
      end
      click_button_and_wait "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "Inteligência Artificial")

      expect(page.all("tr td.name-column").map(&:text)).to eq ["Inteligência Artificial", "Ciência de Dados", "Desenvolvimento Web", "Engenharia de Software"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Ciência de Dados", "Desenvolvimento Web", "Engenharia de Software"]
    end
  end

  describe "edit page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-edit-#{@record.id}-link").click
    end

    it "should be able to edit research_line" do
      within(".as_form") do
        fill_in "Nome", with: "Teste"
      end
      click_button_and_wait "Atualizar"
      expect(page).to have_css("td.name-column", text: "Teste")
      @record.name
      @record.save!
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Buscar"
    end

    it "should be able to search by name" do
      fill_in "Nome", with: "Enge"
      click_button_and_wait "Buscar"
      sleep(0.8)
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Engenharia de Software"]
    end

    it "should be able to search by area" do
      search_record_select("research_area", "research_areas", "Sist")
      click_button_and_wait "Buscar"
      sleep(0.8)
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Desenvolvimento Web"]
    end
  end
end
