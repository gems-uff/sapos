# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# ToDo: test query params

RSpec.describe "Queries features", type: :feature do
  let(:url_path) { "/queries" }
  let(:plural_name) { "queries" }
  let(:model) { Query }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user([@role_adm])

    @destroy_all << FactoryBot.create(:query, name: "students", sql: "select * from students")
    @destroy_all << @record = FactoryBot.create(:query, name: "queries", sql: "select name, sql from queries")
    @destroy_all << FactoryBot.create(:query, name: "levels", sql: "select * from levels")
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
      expect(page).to have_content "Consultas"
      expect(page.all("tr th").map(&:text)).to eq [
        "Nome", "Descrição", "Declarações", "Notificações", ""
      ]
    end

    it "should not have a sorting -- show in id order" do
      expect(page.all("tr td.name-column").map(&:text)).to eq ["students", "queries", "levels"]
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
      expect(page).to have_content "Adicionar Consulta"
      within("#as_#{plural_name}-create--form") do
        fill_in "record_name_", with: "enrollments"
        codemirror = find("#record_sql_ + .CodeMirror").click
        wait_for_ajax
        select_all_keys
        page.driver.browser.action.send_keys(
          :delete, "select * from enrollments"
        ).perform
      end
      click_button_and_wait "Salvar"
      expect(page).to have_no_css(".as_form")
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "enrollments")

      # Remove inserted record
      expect(page.all("tr td.name-column").map(&:text)).to eq ["enrollments", "students", "queries", "levels"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      expect(page).to have_no_content("enrollments")
    end

    it "should have a codemirror for sql" do
      expect(page).to have_selector("#record_sql_ + .CodeMirror", visible: true)
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
      click_button_and_wait "Atualizar"
      expect(page).to have_css("td.description-column", text: "Teste")
    end
  end

  describe "execute link", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-execute-#{@record.id}-link").click
    end

    it "should be able to show query result" do
      expect(page.all("table.query-results tbody tr").size).to eq 3
      expect(page.all("table.query-results thead th").map(&:text)).to eq ["name", "sql"]
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Buscar"
    end

    it "should be able to search by name" do
      fill_in "search", with: "quer"
      expect(page).to have_no_content("students")
      expect(page.all("tr td.name-column").map(&:text)).to eq ["queries"]
    end
  end
end
