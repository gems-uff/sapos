# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Todo: show columns

RSpec.describe "Scholarships features", type: :feature do
  let(:url_path) { "/scholarships" }
  let(:plural_name) { "scholarships" }
  let(:model) { Scholarship }
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

    @destroy_all << FactoryBot.create(:scholarship, scholarship_number: "B2", level: @level2, sponsor: @sponsor1, start_date: 1.years.ago, end_date: 1.year.from_now, scholarship_type: @scholarship_type1)
    @destroy_all << @record = FactoryBot.create(:scholarship, scholarship_number: "B1", level: @level1, sponsor: @sponsor2, start_date: 3.years.ago, end_date: 3.months.from_now, scholarship_type: @scholarship_type1)
    @destroy_all << @scholarship3 = FactoryBot.create(:scholarship, scholarship_number: "B3", level: @level1, sponsor: @sponsor1, start_date: 3.years.ago, end_date: 1.year.from_now, scholarship_type: @scholarship_type2)

    @destroy_all << @student1 = FactoryBot.create(:student, name: "Ana")
    @destroy_all << @enrollment1 = FactoryBot.create(:enrollment, enrollment_number: "M01", student: @student1, level: @level1, enrollment_status: @enrollment_status, admission_date: YearSemester.current.semester_begin - 3.years)

    @destroy_all << FactoryBot.create(:scholarship_duration, enrollment: @enrollment1, scholarship: @scholarship3, start_date: 2.years.ago, end_date: 1.months.from_now)

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
      expect(page).to have_content "Bolsas"
      expect(page.all("tr th").map(&:text)).to eq [
        "Número da Bolsa", "Nível", "Agência", "Tipo", "Data de Início", "Data de Fim", ""
      ]
    end

    it "should sort the list by scholarship_number, asc" do
      expect(page.all("tr td.scholarship_number-column").map(&:text)).to eq ["B1", "B2", "B3"]
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
      expect(page).to have_content "Adicionar Bolsa"
      within("#as_#{plural_name}-create--form") do
        fill_in "Número da Bolsa", with: "B4"
        find(:select, "record_level_").find(:option, text: "Doutorado").select_option
        find(:select, "record_sponsor_").find(:option, text: "CNPq").select_option
      end
      click_button_and_wait "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.scholarship_number-column", text: "B4")

      # Remove inserted record
      expect(page.all("tr td.scholarship_number-column").map(&:text)).to eq ["B4", "B1", "B2", "B3"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.scholarship_number-column").map(&:text)).to eq ["B1", "B2", "B3"]
    end

    it "should have a record_select widget for professor" do
      expect_to_have_record_select(page, "professor_", "professors")
    end

    it "should have a selection for level options" do
      expect(page.all("select#record_level_ option").map(&:text)).to eq ["Selecione uma opção", "Doutorado", "Mestrado"]
    end

    it "should have a selection for sponsor options" do
      expect(page.all("select#record_sponsor_ option").map(&:text)).to eq ["Selecione uma opção", "CAPES", "CNPq"]
    end

    it "should have a selection for scholarship_type options" do
      expect(page.all("select#record_scholarship_type_ option").map(&:text)).to eq ["Selecione uma opção", "Individual", "Projeto"]
    end

    it "should have a month_year widget for start_date" do
      expect_to_have_month_year_widget_i(page, "start_date")
    end

    it "should have an optional month_year widget for end_date" do
      expect_to_have_month_year_widget_i(page, "end_date", "")
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
        find(:select, "record_level_#{@record.id}").find(:option, text: @level2.name).select_option
      end
      click_button_and_wait "Atualizar"
      expect(page).to have_css("#as_#{plural_name}-list-#{@record.id}-row td.level-column", text: "Mestrado")
      @record.level = @level1
      @record.save!
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Buscar"
      sleep(0.2)
    end

    it "should be able to search by scholarship_number" do
      fill_in "Número da Bolsa", with: "B1"
      click_button_and_wait "Buscar"
      expect(page.all("tr td.scholarship_number-column").map(&:text)).to eq ["B1"]
    end

    it "should be able to search by level" do
      find(:select, "search_level").find(:option, text: "Doutorado").select_option
      click_button_and_wait "Buscar"
      expect(page.all("tr td.scholarship_number-column").map(&:text)).to eq ["B1", "B3"]
    end

    it "should be able to search by sponsor" do
      find(:select, "search_sponsor").find(:option, text: "CNPq").select_option
      click_button_and_wait "Buscar"
      expect(page.all("tr td.scholarship_number-column").map(&:text)).to eq ["B2", "B3"]
    end

    it "should be able to search by scholarship_type" do
      find(:select, "search_scholarship_type").find(:option, text: "Individual").select_option
      click_button_and_wait "Buscar"
      expect(page.all("tr td.scholarship_number-column").map(&:text)).to eq ["B1", "B2"]
    end

    it "should be able to search by start_date" do
      select_month_year("search_start_date", 2.years.ago - 1.month)
      click_button_and_wait "Buscar"
      expect(page.all("tr td.scholarship_number-column").map(&:text)).to eq ["B2"]
    end

    it "should be able to search by end_date" do
      select_month_year("search_end_date", 4.months.from_now)
      click_button_and_wait "Buscar"
      expect(page.all("tr td.scholarship_number-column").map(&:text)).to eq ["B2", "B3"]
    end

    it "should be able to search for available scholarships considering scholarship_durations" do
      find(:css, "#search_available_use").set(true)
      select_month_year("date", Date.today)
      click_button_and_wait "Buscar"
      expect(page.all("tr td.scholarship_number-column").map(&:text)).to eq ["B1", "B2"]
    end

    it "should be able to search for available scholarships after scholarship duration" do
      find(:css, "#search_available_use").set(true)
      select_month_year("date", 2.months.from_now)
      click_button_and_wait "Buscar"
      expect(page.all("tr td.scholarship_number-column").map(&:text)).to eq ["B1", "B2", "B3"]
    end

    it "should be able to search for available scholarships considering end_date" do
      find(:css, "#search_available_use").set(true)
      select_month_year("date", 5.months.from_now)
      click_button_and_wait "Buscar"
      expect(page.all("tr td.scholarship_number-column").map(&:text)).to eq ["B2", "B3"]
    end
  end

  describe "generate report", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should download a pdf report of scholarships" do
      click_link_and_wait "Gerar relatório"

      wait_for_download
      expect(download).to match(/Relatório de Bolsas\.pdf/)
    end
  end
end
