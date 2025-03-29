# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "ScholarshipDurations features", type: :feature do
  let(:url_path) { "/scholarship_durations" }
  let(:plural_name) { "scholarship_durations" }
  let(:model) { ScholarshipDuration }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @role_adm = FactoryBot.create :role_administrador
    @destroy_all << @enrollment_status = FactoryBot.create(:enrollment_status, name: "Regular")

    @destroy_all << @level1 = FactoryBot.create(:level, name: "Doutorado")
    @destroy_all << @level2 = FactoryBot.create(:level, name: "Mestrado")

    @destroy_all << @sponsor1 = FactoryBot.create(:sponsor, name: "CNPq")
    @destroy_all << @sponsor2 = FactoryBot.create(:sponsor, name: "CAPES")

    @destroy_all << @scholarship_type1 = FactoryBot.create(:scholarship_type, name: "Individual")
    @destroy_all << @scholarship_type2 = FactoryBot.create(:scholarship_type, name: "Projeto")

    @destroy_all << @scholarship1 = FactoryBot.create(:scholarship, scholarship_number: "B1", level: @level2, sponsor: @sponsor1, start_date: 8.years.ago.at_beginning_of_month, end_date: 1.year.from_now.at_beginning_of_month, scholarship_type: @scholarship_type1)
    @destroy_all << @scholarship2 = FactoryBot.create(:scholarship, scholarship_number: "B2", level: @level1, sponsor: @sponsor2, start_date: 6.years.ago.at_beginning_of_month, end_date: 4.years.from_now.at_beginning_of_month, scholarship_type: @scholarship_type1)
    @destroy_all << @scholarship3 = FactoryBot.create(:scholarship, scholarship_number: "B3", level: @level1, sponsor: @sponsor1, start_date: 6.years.ago.at_beginning_of_month, end_date: 1.year.from_now.at_beginning_of_month, scholarship_type: @scholarship_type2)

    @destroy_all << @student1 = FactoryBot.create(:student, name: "Ana")
    @destroy_all << @student2 = FactoryBot.create(:student, name: "Bia")
    @destroy_all << @student3 = FactoryBot.create(:student, name: "Carol")
    @destroy_all << @student4 = FactoryBot.create(:student, name: "Dani")
    @destroy_all << @enrollment1 = FactoryBot.create(:enrollment, enrollment_number: "M01", student: @student1, level: @level2, enrollment_status: @enrollment_status, admission_date: 3.years.ago.at_beginning_of_month.to_date)
    @destroy_all << @enrollment2 = FactoryBot.create(:enrollment, enrollment_number: "M02", student: @student2, level: @level1, enrollment_status: @enrollment_status)
    @destroy_all << @enrollment3 = FactoryBot.create(:enrollment, enrollment_number: "M03", student: @student3, level: @level1, enrollment_status: @enrollment_status)
    @destroy_all << @enrollment4 = FactoryBot.create(:enrollment, enrollment_number: "M04", student: @student4, level: @level1, enrollment_status: @enrollment_status)

    @destroy_all << @record = FactoryBot.create(:scholarship_duration, enrollment: @enrollment1, scholarship: @scholarship1, start_date: 2.years.ago.at_beginning_of_month, end_date: 1.months.from_now.at_beginning_of_month)
    @destroy_all << @scholarship_duration2 = FactoryBot.create(:scholarship_duration, enrollment: @enrollment2, scholarship: @scholarship2, start_date: 3.years.ago.at_beginning_of_month, end_date: 2.years.from_now.at_beginning_of_month)
    @destroy_all << FactoryBot.create(:scholarship_duration, enrollment: @enrollment3, scholarship: @scholarship2, start_date: 6.years.ago.at_beginning_of_month, cancel_date: 5.years.ago.at_beginning_of_month, end_date: 4.years.ago.at_beginning_of_month)

    @destroy_all << @scholarship_suspension1 = FactoryBot.create(:scholarship_suspension, scholarship_duration: @record, start_date: 1.year.ago.at_beginning_of_month, end_date: 6.months.ago.at_beginning_of_month, active: true)
    @destroy_all << @scholarship_suspension2 = FactoryBot.create(:scholarship_suspension, scholarship_duration: @scholarship_duration2, start_date: 1.month.ago.at_beginning_of_month, end_date: 1.month.from_now.at_beginning_of_month, active: false)


    @destroy_all << @professor1 = FactoryBot.create(:professor, name: "Erica", cpf: "3")
    @destroy_all << FactoryBot.create(:advisement, enrollment: @enrollment1, professor: @professor1, main_advisor: true)

    @destroy_all << @user = create_confirmed_user(@role_adm)
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @role_adm.delete
    @destroy_all.each(&:delete)
    @destroy_all.clear
  end

  describe "view list page" do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should show table" do
      expect(page).to have_content "Alocação de Bolsas"
      expect(page.all("tr th").map(&:text)).to eq [
        "Número da Bolsa", "Data de Início", "Data Limite de Concessão", "Data de Encerramento", "Matrícula", ""
      ]
    end

    it "should not have a sorting -- show in id order" do
      expect(page.all("tr td.scholarship-column").map(&:text)).to eq ["B1", "B2", "B2"]
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
      expect(page).to have_content "Adicionar Bolsa"
      fill_record_select("scholarship_", "scholarships", "B3")
      page.send_keys :escape
      fill_record_select("enrollment_", "enrollments", "M04")
      click_button "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.scholarship-column", text: "B3")
      expect(page).to have_css("tr:nth-child(1) td.enrollment-column", text: "M04")

      # Remove inserted record
      expect(page.all("tr td.scholarship-column").map(&:text)).to eq ["B3", "B1", "B2", "B2"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.scholarship-column").map(&:text)).to eq ["B1", "B2", "B2"]
    end

    it "should have a record_select widget for scholarship" do
      expect_to_have_record_select(page, "scholarship_", "scholarships")
    end

    it "should have a record_select widget for enrollment" do
      page.send_keys :escape
      expect_to_have_record_select(page, "enrollment_", "enrollments")
    end

    it "should have a month_year widget for start_date" do
      page.send_keys :escape
      expect_to_have_month_year_widget_i(page, "start_date")
    end

    it "should have an optional month_year widget for end_date" do
      page.send_keys :escape
      expect_to_have_month_year_widget_i(page, "end_date", "")
    end

    it "should have an optional month_year widget for cancel_date" do
      page.send_keys :escape
      expect_to_have_month_year_widget_i(page, "cancel_date", "")
    end
  end

  describe "edit page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-edit-#{@record.id}-link").click
    end

    it "should be able to edit record" do
      date = 3.months.from_now
      within(".as_form") do
        select_month_year_i("record_end_date", date)
      end
      click_button "Atualizar"
      expect(page).to have_css("#as_#{plural_name}-list-#{@record.id}-row td.end_date-column", text: I18n.l(date, format: "%B-%Y"))
      @record.end_date = 1.month.from_now
      @record.save!
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by scholarship" do
      fill_in "Número da Bolsa", with: "B1"
      click_button "Buscar"
      expect(page.all("tr td.scholarship-column").map(&:text)).to eq ["B1"]
    end

    it "should be able to search by start_date" do
      select_month_year("search_start_date", 3.years.ago.at_beginning_of_month)
      click_button "Buscar"
      expect(page.all("tr td.scholarship-column").map(&:text)).to eq ["B1", "B2"]
    end

    it "should be able to search by end_date" do
      select_month_year("search_end_date", 9.months.from_now.at_beginning_of_month)
      click_button "Buscar"
      expect(page.all("tr td.scholarship-column").map(&:text)).to eq ["B2"]
    end

    it "should be able to search by cancel_date" do
      select_month_year("search_cancel_date", 5.years.ago.at_beginning_of_month)
      click_button "Buscar"
      expect(page.all("tr td.scholarship-column").map(&:text)).to eq ["B2"]
    end

    it "should be able to search by enrollment" do
      fill_in "Matrícula", with: "M01"
      click_button "Buscar"
      expect(page.all("tr td.scholarship-column").map(&:text)).to eq ["B1"]
    end

    it "should be able to search by advisor" do
      search_record_select("adviser", "professors", "Erica")
      click_button "Buscar"
      expect(page.all("tr td.scholarship-column").map(&:text)).to eq ["B1"]
    end

    it "should be able to search by sponsor" do
      expect(page.all("select#search_sponsors option").map(&:text)).to eq ["", "CAPES", "CNPq"]
      find(:select, "search_sponsors").find(:option, text: "CNPq").select_option
      click_button "Buscar"
      expect(page.all("tr td.scholarship-column").map(&:text)).to eq ["B1"]
    end

    it "should be able to search by scholarship_type" do
      expect(page.all("select#search_scholarship_types option").map(&:text)).to eq ["", "Individual", "Projeto"]
      find(:select, "search_scholarship_types").find(:option, text: "Individual").select_option
      click_button "Buscar"
      expect(page.all("tr td.scholarship-column").map(&:text)).to eq ["B1", "B2", "B2"]
    end

    it "should be able to search by level" do
      expect(page.all("select#search_level option").map(&:text)).to eq ["", "Doutorado", "Mestrado"]
      find(:select, "search_level").find(:option, text: "Doutorado").select_option
      click_button "Buscar"
      expect(page.all("tr td.scholarship-column").map(&:text)).to eq ["B2", "B2"]
    end

    it "should be able to search by active" do
      expect(page.all("select#search_active option").map(&:text)).to eq ["Todas", "Ativas", "Inativas"]
      find(:select, "search_active").find(:option, text: "Inativas").select_option
      click_button "Buscar"
      expect(page.all("tr td.scholarship-column").map(&:text)).to eq ["B2"]
    end

    it "should be able to search by active suspensions" do
      find(:select, "search_suspended_active_suspension").find(:option, text: "Alguma").select_option
      click_button "Buscar"
      expect(page.all("tr td.scholarship-column").map(&:text)).to eq ["B1"]
    end

    it "should be able to search by the time interval of suspension" do
      start_year = 0.years.ago.year
      find(:select, "suspended_start_year").find(:option, text: start_year.to_s).select_option

      start_month = I18n.l(2.months.ago, format: "%B")
      find(:select, "suspended_start_month").find(:option, text: start_month).select_option

      end_year = 0.years.ago.year
      find(:select, "suspended_end_year").find(:option, text: end_year.to_s).select_option

      end_month = I18n.l(2.months.from_now, format: "%B")
      find(:select, "suspended_end_month").find(:option, text: end_month).select_option

      click_button "Buscar"
      expect(page.all("tr td.scholarship-column").map(&:text)).to eq ["B2"]
    end
  end

  describe "generate report", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should download a pdf report of scholarships" do
      click_link "Gerar relatório"

      wait_for_download
      expect(download).to match(/Relatório de Alocação de Bolsas\.pdf/)
    end
  end
end
