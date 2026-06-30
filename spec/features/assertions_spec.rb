# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Assertions features", type: :feature do
  let(:url_path) { "/assertions" }
  let(:plural_name) { "assertions" }
  let(:model) { Assertion }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user([@role_adm])

    @destroy_all << @query1 = FactoryBot.create(:query, name: "students", sql: "select * from students")
    @destroy_all << @query2 = FactoryBot.create(:query, name: "queries", sql: "select 1 as col")

    @destroy_all << @assertion1 = Assertion.create!(
      name: "Declaracao A",
      query: @query1,
      template_type: "Liquid",
      assertion_template: "Olá {{ aluno }}",
      student_can_generate: false
    )
    @destroy_all << @record = Assertion.create!(
      name: "Declaracao B",
      query: @query2,
      template_type: "Liquid",
      assertion_template: "Conclusão",
      student_can_generate: false
    )
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
      expect(page).to have_content "Declarações"
      expect(page.all("tr th").map(&:text)).to eq [
        "Nome da Declaração", "Consulta", ""
      ]
    end

    it "should sort records by name ASC" do
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Declaracao A", "Declaracao B"]
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
      expect(page).to have_content "Adicionar Declaração"
      within("#as_#{plural_name}-create--form") do
        fill_in "Nome da Declaração", with: "Declaracao C"
        find(:select, "record_query_").find(:option, text: "queries").select_option
        find(:select, "record_template_type_").find(:option, text: Assertion::LIQUID).select_option
      end
      click_button_and_wait "Salvar"
      expect(page).to have_no_css(".as_form")
      expect(page).to have_css("td.name-column", text: "Declaracao C")

      # Remove inserted record
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Declaracao C", "Declaracao A", "Declaracao B"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      expect(page).to have_no_content("Declaracao C")
    end

    it "should have a codemirror for assertion template" do
      expect(page).to have_selector("#record_assertion_template_ + .codemirror-toolbar + .CodeMirror", visible: true)
    end

    it "should have a toggable codemirror for the query SQL" do
      expect(page).to have_selector("#record_query_container .CodeMirror-code", visible: true)

      click_link_and_wait "SQL"
      expect(page).to have_selector("#record_query_container .CodeMirror-code", visible: false)

      click_link_and_wait "SQL"
      expect(page).to have_selector("#record_query_container .CodeMirror-code", visible: true)
    end

    it "should have a selection for template type" do
      expect(page.all("select#record_template_type_ option").map(&:text)).to include(*Assertion::TEMPLATE_TYPES)
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
        fill_in "Nome da Declaração", with: "Teste"
      end
      click_button_and_wait "Atualizar"
      expect(page).to have_css("td.name-column", text: "Teste")
      @record.name = "Declaracao B"
      @record.save!
    end
  end

  describe "simulate link", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-simulate-#{@record.id}-link").click
    end

    it "should render the simulate page for the assertion" do
      expect(page).to have_content @record.to_label
      expect(page).to have_css("#as_#{plural_name}-simulate-#{@record.id}-link")
    end

    it "should display the executed SQL and the simulation results" do
      expect(page.all("table.assertion-results thead th").map(&:text)).to eq ["col"]
      expect(page.all("table.assertion-results tbody tr").size).to eq 1
      expect(page.all("table.assertion-results tbody td").map(&:text)).to eq ["1"]

      click_link_and_wait "SQL"
      expect(page).to have_css("#generated_sql", visible: true, text: "select 1 as col")
    end
  end
end
