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
    @destroy_all << @user = create_confirmed_user([@role_adm])

    @destroy_all << @level1 = FactoryBot.create(:level, name: "Doutorado")
    @destroy_all << @level2 = FactoryBot.create(:level, name: "Mestrado")
    @destroy_all << @enrollment_status1 = FactoryBot.create(:enrollment_status, name: "Regular")
    @destroy_all << @student1 = FactoryBot.create(:student, name: "Ana", email: "ana.sapos@ic.uff.br")
    @destroy_all << @enrollment1 = FactoryBot.create(:enrollment, enrollment_number: "M02", student: @student1, level: @level2, enrollment_status: @enrollment_status1, admission_date: YearSemester.current.semester_begin - 3.years)
    @destroy_all << FactoryBot.create(:enrollment, enrollment_number: "D02", student: @student1, level: @level1, enrollment_status: @enrollment_status1, admission_date: YearSemester.current.semester_begin - 3.years)

    @destroy_all << @query1 = FactoryBot.create(:query, name: "students", sql: "select * from students")
    @query2 = FactoryBot.build(:query, name: "queries", sql: "select name, `sql`, :ano_semestre_atual as temp from queries")
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
    UserRole.delete_all
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
      click_link_and_wait "Adicionar"
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
      expect(page).to have_no_css(".as_form")
      expect(page).to have_css("tr:nth-child(1) td.title-column", text: "Query")

      # Remove inserted record
      expect(page.all("tr td.title-column").map(&:text)).to eq ["Query", "saudacao", "despedida", "boletim", "lembrete"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      expect(page).to have_no_content("Query")
    end

    it "should have a codemirror for body template" do
      expect(page).to have_selector("#record_body_template_ + .codemirror-toolbar + .CodeMirror", visible: true)
    end

    it "should have a codemirror to view selected query" do
      find(:select, "record_query_").find(:option, text: "queries").select_option
      expect(page).to have_css("#record_query_container .CodeMirror-code", text: <<~TEXT.chomp
        1
        select name, `sql`, :ano_semestre_atual as temp from queries
      TEXT
      )

      click_link_and_wait "SQL"
      expect(page).to have_selector("#record_query_container .CodeMirror-code", visible: false)

      click_link_and_wait "SQL"
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
      click_link_and_wait "Notificar agora"
      expect(page).to have_content "Notificação disparada com sucesso"
    end
  end

  # Notifications used to be triggered by GET /notifications/notify, an
  # unauthenticated endpoint. Production drives them through the daily cron
  # (bundle exec rails maintenance:run), so the rake task is what these
  # examples exercise.
  describe "maintenance:trigger_notifications" do
    before(:all) do
      require "rake"
      Rails.application.load_tasks if Rake::Task.tasks.empty?
    end

    before(:each) do
      Rake::Task["maintenance:trigger_notifications"].reenable
      # Os objetos vem do before(:all) e sobrevivem aos exemplos, guardando o
      # next_execution que o exemplo anterior atribuiu -- mas o banco voltou ao
      # valor original pelo rollback. Como notifications.next_execution e
      # datetime sem precisao fracionaria, em MySQL/MariaDB dois `5.days.ago`
      # dentro do mesmo segundo sao o mesmo valor: o dirty tracking nao ve
      # mudanca, o save! vira no-op e a notificacao fica fora da janela do rake,
      # sem e-mail nenhum. O SQLite guarda a fracao de segundo e escondia isso.
      [@notification3, @notification4].each(&:reload)
    end

    it "should send notifications with attachment" do
      @notification3.next_execution = 5.days.ago
      @notification3.save!
      Rake::Task["maintenance:trigger_notifications"].invoke
      expect(ActionMailer::Base.deliveries.last.subject).to eq "SAPOS: boletim em anexo"
    end

    # The attachment goes out EMPTY through the rake task -- see issue #632.
    # The fix for #547 taught the controller copy of prepare_attachments to pass
    # filename, signature_type and watermark, but never reached the rake copy,
    # which still calls render_enrollments_grades_report_pdf with a single
    # argument. From outside a controller, render_to_string returns nil, so
    # file_contents ends up empty and nothing is raised.
    #
    # No one is affected: the feature has been unused in production since early
    # 2025, when students started generating the report themselves with a QR
    # code. #632 decides whether the option is removed or the task is fixed.
    # This example pins the current behavior so that either decision breaks it
    # and forces a rewrite.
    it "currently attaches an EMPTY grades report (see #632)" do
      @notification3.next_execution = 5.days.ago
      @notification3.save!
      Rake::Task["maintenance:trigger_notifications"].invoke

      attachment = ActionMailer::Base.deliveries.last.attachments.first
      expect(attachment).to be_present
      expect(attachment.filename).to include("BOLETIM")
      expect(attachment.body.raw_source.bytesize).to eq 0
    end

    it "should send notifications without attachment" do
      @notification4.next_execution = 5.days.ago
      @notification4.save!
      Rake::Task["maintenance:trigger_notifications"].invoke
      expect(ActionMailer::Base.deliveries.last.subject).to eq "SAPOS: lembrar de etapa"
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Buscar"
    end

    it "should be able to search by title" do
      fill_in "search", with: "lemb"
      expect(page).to have_no_content("despedida")
      expect(page.all("tr td.title-column").map(&:text)).to eq ["lembrete"]
    end
  end
end
