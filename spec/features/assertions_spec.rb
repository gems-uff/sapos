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

    it "should generate the pdf from the simulation" do
      expect(page).to have_css("#generate-pdf-link")

      find("#generate-pdf-link").click

      wait_for_download
      expect(download).to match(/\.pdf\z/)
    end
  end

  # O botao de PDF monta um formulario GET em JavaScript e o submete, repassando
  # os parametros da simulacao. Eles vem de um data-attribute, e nao interpolados
  # no corpo do script: no atributo o escape do ERB e obrigatorio.
  #
  # A consulta aqui PRECISA ter parametro. Com uma consulta sem parametro o
  # clique baixa um PDF de qualquer jeito, mesmo que o data-attribute nao seja
  # lido -- foi o que aconteceu na primeira versao deste teste, que passava com
  # o atributo renomeado. So o valor digitado chegando ao PDF prova o percurso.
  describe "generate pdf carrying the simulation parameters", js: true do
    before(:each) do
      query = Query.new(name: "nome_param", sql: "select :nome as col")
      query.params.build(
        name: "nome", value_type: "String", default_value: "PADRAO"
      )
      query.save!
      @destroy_later << query
      @destroy_later << @param_assertion = Assertion.create!(
        name: "Declaracao parametrizada", query: query,
        template_type: "Liquid", assertion_template: "Valor: {{ col }}",
        student_can_generate: false
      )
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-simulate-#{@param_assertion.id}-link").click
    end

    it "should carry the typed parameter into the generated pdf" do
      field = "assertion_#{@param_assertion.id}_nome"
      fill_in field, with: "TOKENDOPDF"
      # O change e o que repassa o valor para a query string do action link; o
      # blur do Capybara nao e garantia de dispara-lo.
      page.execute_script("$('##{field}').trigger('change')")

      click_link_and_wait "Simular"
      expect(page).to have_css("table.assertion-results tbody td", text: "TOKENDOPDF")

      find("#generate-pdf-link").click
      wait_for_download

      text = PDF::Reader.new(download).pages.map(&:text).join("\n")
      expect(text).to include("TOKENDOPDF")
    end
  end

  # Issue #624: só a carga direta reproduz. Sem o action link do ActiveScaffold
  # no DOM, link.prop("search") é undefined, o .replace estoura e o script morre
  # antes de inicializar o datepicker.
  describe "simulate page with date param loaded directly", js: true do
    before(:each) do
      query = Query.new(name: "data_param", sql: "select :data as col")
      query.params.build(name: "data", value_type: "Date", default_value: "")
      query.save!
      @destroy_later << query
      @destroy_later << @date_assertion = Assertion.create!(
        name: "Declaracao data", query: query,
        template_type: "Liquid", assertion_template: "Corpo",
        student_can_generate: false
      )
      login_as(@user)
      visit "/assertions/#{@date_assertion.id}/simulate"
    end

    it "should initialize datepicker on date param fields" do
      expect(page).to have_css("input._param_type_date.hasDatepicker")
    end
  end

  # Issue #640: mesmo defeito da simulacao de notificacao -- um valor longo sem
  # espaco nao tem ponto de quebra, a celula estica a tabela e a pagina inteira
  # passa a rolar na horizontal.
  describe "simulate page with a long value", js: true do
    before(:each) do
      long_token = "https://www.example.com/documentos/regras/" +
        ("REGRAS_DE_PRORROGACAO_E_QUALIFICACAO_" * 6)
      @destroy_later << @long_query = FactoryBot.create(
        :query, name: "longa", sql: "select '#{long_token}' as col"
      )
      @destroy_later << @long_assertion = Assertion.create!(
        name: "Declaracao longa", query: @long_query,
        template_type: "Liquid", assertion_template: "Corpo",
        student_can_generate: false
      )
      login_as(@user)
      page.driver.browser.manage.window.resize_to(1280, 900)
      visit url_path
      find("#as_#{plural_name}-simulate-#{@long_assertion.id}-link").click
    end

    it "should not make the page scroll horizontally" do
      expect(page).to have_css("table.assertion-results tbody tr")

      overflow = page.evaluate_script(
        "document.documentElement.scrollWidth - document.documentElement.clientWidth"
      )
      expect(overflow).to be <= 0
    end
  end
end
