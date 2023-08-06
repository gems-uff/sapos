# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "EnrollmentHolds features", type: :feature do
  let(:url_path) { "/enrollment_holds" }
  let(:plural_name) { "enrollment_holds" }
  let(:model) { EnrollmentHold }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user(@role_adm)
    @destroy_all << @level = FactoryBot.create(:level, name: "Doutorado")
    @destroy_all << @enrollment_status = FactoryBot.create(:enrollment_status, name: "Regular")
    @destroy_all << @student1 = FactoryBot.create(:student, name: "Ana")
    @destroy_all << @student2 = FactoryBot.create(:student, name: "Bia")
    @destroy_all << @student3 = FactoryBot.create(:student, name: "Carol")
    @destroy_all << @student4 = FactoryBot.create(:student, name: "Dani")
    @destroy_all << @enrollment1 = FactoryBot.create(:enrollment, enrollment_number: "M02", student: @student1, level: @level, enrollment_status: @enrollment_status, admission_date: 3.years.ago.to_date)
    @destroy_all << @enrollment2 = FactoryBot.create(:enrollment, enrollment_number: "M01", student: @student2, level: @level, enrollment_status: @enrollment_status, admission_date: 3.years.ago.to_date)
    @destroy_all << @enrollment3 = FactoryBot.create(:enrollment, enrollment_number: "M03", student: @student3, level: @level, enrollment_status: @enrollment_status, admission_date: 3.years.ago.to_date)
    @destroy_all << @enrollment4 = FactoryBot.create(:enrollment, enrollment_number: "M04", student: @student4, level: @level, enrollment_status: @enrollment_status, admission_date: 3.years.ago.to_date)

    @destroy_all << @record = FactoryBot.create(:enrollment_hold, enrollment: @enrollment1, year: YearSemester.current.year, semester: YearSemester.current.semester, number_of_semesters: 1)
    @destroy_all << FactoryBot.create(:enrollment_hold, enrollment: @enrollment2, year: YearSemester.current.year, semester: YearSemester.current.semester, number_of_semesters: 1, active: false)
    @destroy_all << FactoryBot.create(:enrollment_hold, enrollment: @enrollment3, year: YearSemester.current.year, semester: YearSemester.current.semester, number_of_semesters: 1)
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
      expect(page).to have_content "Trancamentos"
      expect(page.all("tr th").map(&:text)).to eq [
        "Matrícula", "Ano", "Semestre", "Número de Semestres", "Trancado?", ""
      ]
    end

    it "should not have a sorting -- show in id order" do
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Ana", "M01 - Bia", "M03 - Carol"]
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
      expect(page).to have_content "Adicionar Trancamento"
      within("#as_#{plural_name}-create--form") do
        fill_in "Matrícula", with: "M04"
        find("#record_enrollment_").click
        sleep(0.5)
      end
      find("#record-select-enrollments .current").click
      within("#as_#{plural_name}-create--form") do
        find(:select, "record_year_").find(:option, text: YearSemester.current.year.to_s).select_option
        find(:select, "record_semester_").find(:option, text: YearSemester.current.semester.to_s).select_option
      end
      click_button "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.enrollment-column", text: "M04")
      expect(page).to have_css("tr:nth-child(1) td.year-column", text: YearSemester.current.year.to_s)
      expect(page).to have_css("tr:nth-child(1) td.semester-column", text: YearSemester.current.semester.to_s)

      # Remove inserted record
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M04 - Dani", "M02 - Ana", "M01 - Bia", "M03 - Carol"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Ana", "M01 - Bia", "M03 - Carol"]
    end

    it "should have a record_select widget for enrollment" do
      find("#record_enrollment_").click
      sleep(0.2)
      expect(page).to have_selector("#record-select-enrollments", visible: true)
    end
  end

  describe "edit page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-edit-#{@record.id}-link").click
    end

    it "should be able to edit dismissals" do
      within(".as_form") do
        fill_in "Número de Semestres", with: "2"
      end
      click_button "Atualizar"
      expect(page).to have_css("tr:nth-child(1) td.number_of_semesters-column", text: "2")
    end

  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by enrollment" do
      fill_in "Matrícula", with: "M03"
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M03 - Carol"]
    end

    it "should be able to search by active = yes" do
      find(:select, "search_active").find(:option, text: "Sim").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Ana", "M03 - Carol"]
    end

    it "should be able to search by active = no" do
      find(:select, "search_active").find(:option, text: "Não").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Bia"]
    end
  end
end
