# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# ToDo: test notifications params

RSpec.describe "Notifications features", type: :feature do
  let(:url_path) { "/notifications" }
  let(:plural_name) { "notifications" }
  let(:model) { Notification }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user(@role_adm)

    @destroy_all << @level1 = FactoryBot.create(:level, name: "Doutorado")
    @destroy_all << @level2 = FactoryBot.create(:level, name: "Mestrado")
    @destroy_all << @enrollment_status1 = FactoryBot.create(:enrollment_status, name: "Regular")
    @destroy_all << @student1 = FactoryBot.create(:student, name: "Ana", email: "ana.sapos@ic.uff.br")
    @destroy_all << @enrollment1 = FactoryBot.create(:enrollment, enrollment_number: "M02", student: @student1, level: @level2, enrollment_status: @enrollment_status1, admission_date: 3.years.ago.at_beginning_of_month.to_date)
    @destroy_all << FactoryBot.create(:enrollment, enrollment_number: "D02", student: @student1, level: @level1, enrollment_status: @enrollment_status1, admission_date: 3.years.ago.at_beginning_of_month.to_date)

    @destroy_all << @query1 = FactoryBot.create(:query, name: "students", sql: "select * from students")
    @query2 = FactoryBot.build(:query, name: "queries", sql: "select name, sql, :ano_semestre_atual as temp from queries")
    @destroy_all << @query2.params.build(name: "ano_semestre_atual", value_type: "Integer", default_value: "")
    @query2.save!
    @destroy_all << @query3 = FactoryBot.create(:query, name: "enrollments", sql: "select id as enrollments_id from enrollments")


    @destroy_all << @query2

    @destroy_all << FactoryBot.create(:notification, query: @query1, title: "saudacao", to_template: "jpimentel@ic.uff.br", subject_template: "Olá", body_template: "Corpo")
    @destroy_all << @record = FactoryBot.create(:notification, query: @query2, title: "despedida", to_template: "jpimentel@ic.uff.br", subject_template: "Tchau", body_template: "<%= var('name') %>")
    @destroy_all << @notification3 = FactoryBot.create(:notification, query: @query3, title: "boletim", to_template: "jpimentel@ic.uff.br", subject_template: "SAPOS: boletim em anexo", body_template: "Corpo", frequency: "Anual", has_grades_report_pdf_attachment: true, individual: true)
    @destroy_all << @notification4 = FactoryBot.create(:notification, query: @query3, title: "lembrete", to_template: "jpimentel@ic.uff.br", subject_template: "SAPOS: lembrar de etapa", body_template: "Corpo", frequency: "Anual", has_grades_report_pdf_attachment: false, individual: true)
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
      expect(page).to have_content "Notificações"
      expect(page.all("tr th").map(&:text)).to eq [
        "Título", "Frequência", "Offset da Notificação", "Offset da Consulta", "Próxima Execução", ""
      ]
    end

    it "should not have a sorting -- show in id order" do
      expect(page.all("tr td.title-column").map(&:text)).to eq ["saudacao", "despedida", "boletim", "lembrete"]
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
      expect(page).to have_content "Adicionar Notificação"
      within("#as_#{plural_name}-create--form") do
        fill_in "Título", with: "Query"
        fill_in "Template do Destinatário", with: "jpimentel@ic.uff.br"
        fill_in "Template do Assunto", with: "Assunto"
        find(:select, "record_query_").find(:option, text: "queries").select_option
      end
      click_button_and_wait "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.title-column", text: "Query")

      # Remove inserted record
      expect(page.all("tr td.title-column").map(&:text)).to eq ["Query", "saudacao", "despedida", "boletim", "lembrete"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.title-column").map(&:text)).to eq ["saudacao", "despedida", "boletim", "lembrete"]
    end

    it "should have a codemirror for body template" do
      expect(page).to have_selector("#record_body_template_ + .CodeMirror", visible: true)
    end

    it "should have a codemirror to view selected query" do
      find(:select, "record_query_").find(:option, text: "queries").select_option
      expect(page).to have_css("#record_query_container .CodeMirror-code", text: <<~TEXT.chomp
        1
        select name, sql, :ano_semestre_atual as temp from queries
      TEXT
      )

      click_link "SQL"
      expect(page).to have_selector("#record_query_container .CodeMirror-code", visible: false)

      click_link "SQL"
      expect(page).to have_selector("#record_query_container .CodeMirror-code", visible: true)
    end

    it "should have a selection for frequency" do
      expect(page.all("select#record_frequency_ option").map(&:text)).to eq (Notification::FREQUENCIES)
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
        fill_in "Título", with: "Teste"
      end
      click_button_and_wait "Atualizar"
      expect(page).to have_css("td.title-column", text: "Teste")
      @record.title = "despedida"
      @record.save!
    end
  end

  describe "simulate link", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-simulate-#{@record.id}-link").click
    end

    it "should be able to preview emails" do
      expect(page.all("table.notification-results tbody tr").size).to eq 3
      expect(page.all("table.notification-results thead th").map(&:text)).to eq ["Para", "Assunto", "Corpo"]
    end

    it "should be able to notify now" do
      click_link "Notificar agora"
      expect(page).to have_content "Notificação disparada com sucesso"
    end
  end

  describe "notify" do
    it "should send notifications with attachment" do
      @notification3.next_execution = 5.days.ago
      @notification3.save!
      visit "/notifications/notify"
      expect(page).to have_content "Ok"
      expect(ActionMailer::Base.deliveries.last.subject).to eq "SAPOS: boletim em anexo"
    end

    it "should send notifications without attachment" do
      @notification4.next_execution = 5.days.ago
      @notification4.save!
      visit "/notifications/notify"
      expect(page).to have_content "Ok"
      expect(ActionMailer::Base.deliveries.last.subject).to eq "SAPOS: lembrar de etapa"
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by title" do
      fill_in "search", with: "lemb"
      sleep(0.8)
      expect(page.all("tr td.title-column").map(&:text)).to eq ["lembrete"]
    end
  end
end
