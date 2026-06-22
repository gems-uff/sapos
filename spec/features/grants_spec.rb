# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Grants features", type: :feature do
  let(:url_path) { "/grants" }
  let(:plural_name) { "grants" }
  let(:model) { Grant }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @role_adm = FactoryBot.create :role_administrador

    @destroy_all << @professor1 = FactoryBot.create(:professor, name: "Ana", cpf: "1")
    @destroy_all << @professor2 = FactoryBot.create(:professor, name: "Bia", cpf: "2")

    @destroy_all << @record = FactoryBot.create(:grant,
      title: "Projeto Alpha",
      start_year: 2022,
      end_year: 2024,
      professor: @professor1,
      kind: Grant::PUBLIC,
      funder: "CNPq",
      amount: 100000
    )
    @destroy_all << FactoryBot.create(:grant,
      title: "Projeto Beta",
      start_year: 2023,
      end_year: 2025,
      professor: @professor2,
      kind: Grant::PRIVATE,
      funder: "Empresa XYZ",
      amount: 50000
    )

    @destroy_all << @user = create_confirmed_user([@role_adm])
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @role_adm.delete
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
      expect(page).to have_content "Coordenações de Projetos"
      expect(page.all("tr th").map(&:text)).to eq [
        "Título", "Ano de Início", "Ano de Término", "Coordenador", "Tipo de financiamento", "Financiador", "Valor total", ""
      ]
    end

    it "should not have a sorting -- show in id order" do
      expect(page.all("tr td.title-column").map(&:text)).to eq ["Projeto Alpha", "Projeto Beta"]
    end
  end

  describe "insert page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Adicionar"
    end

    it "should be able to insert and remove record" do
      expect(page).to have_content "Adicionar Coordenação de Projeto"
      within("#as_#{plural_name}-create--form") do
        fill_in "Título", with: "Projeto Gamma"
        fill_in "Ano de Início", with: "2024"
        fill_in "Ano de Término", with: "2025"
        find(:select, "record_kind_").find(:option, text: Grant::PUBLIC).select_option
        fill_in "Financiador", with: "FAPERJ"
        fill_in "Valor total", with: "75000"
      end
      fill_record_select("professor_", "professors", "Ana")
      click_button_and_wait "Salvar"
      expect(page).to have_no_css(".as_form")
      expect(page).to have_css("tr:nth-child(1) td.title-column", text: "Projeto Gamma")

      expect(page.all("tr td.title-column").map(&:text).count).to eq 3
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      expect(page).to have_no_content("Projeto Gamma")
    end

    it "should have a select for kind options" do
      expect(page.all("select#record_kind_ option").map(&:text)).to include(
        Grant::PUBLIC, Grant::PRIVATE
      )
    end
  end

  describe "edit page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-edit-#{@record.id}-link").click
    end

    it "should be able to edit record" do
      within(".as_form") do
        fill_in "Título", with: "Projeto Alpha 2.0"
      end
      click_button_and_wait "Atualizar"
      expect(page).to have_css(
        "#as_#{plural_name}-list-#{@record.id}-row td.title-column",
        text: "Projeto Alpha 2.0"
      )
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Buscar"
    end

    it "should be able to search by title" do
      fill_in "search_title_from", with: "Alpha"
      click_button_and_wait "Buscar"
      expect(page.all("tr td.title-column").map(&:text)).to eq ["Projeto Alpha"]
    end

    it "should be able to search by kind" do
      find(:select, "search_kind").find(:option, text: Grant::PRIVATE).select_option
      click_button_and_wait "Buscar"
      expect(page.all("tr td.title-column").map(&:text)).to eq ["Projeto Beta"]
    end

    it "should be able to search by professor" do
      search_record_select("professor", "professors", "Bia")
      click_button_and_wait "Buscar"
      expect(page.all("tr td.title-column").map(&:text)).to eq ["Projeto Beta"]
    end

    it "should be able to search by start_year" do
      fill_in "search_start_year", with: "2023"
      click_button_and_wait "Buscar"
      expect(page.all("tr td.title-column").map(&:text)).to eq ["Projeto Beta"]
    end

    it "should be able to search by end_year" do
      fill_in "search_end_year", with: "2024"
      click_button_and_wait "Buscar"
      expect(page.all("tr td.title-column").map(&:text)).to eq ["Projeto Alpha"]
    end

    it "should be able to search by funder" do
      fill_in "search_funder_from", with: "Empresa XYZ"
      click_button_and_wait "Buscar"
      expect(page.all("tr td.title-column").map(&:text)).to eq ["Projeto Beta"]
    end

    it "should be able to search by amount" do
      fill_in "search_amount", with: "100000"
      click_button_and_wait "Buscar"
      expect(page.all("tr td.title-column").map(&:text)).to eq ["Projeto Alpha"]
    end
  end
end
