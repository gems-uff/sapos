# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# ToDo: relationships
# ToDo: search
# ToDo: add users
# ToDo: Reports

RSpec.describe "Enrollments features", type: :feature do
  let(:url_path) { "/enrollments" }
  let(:plural_name) { "enrollments" }
  let(:model) { Enrollment }
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

    @destroy_all << @record = FactoryBot.create(:enrollment, enrollment_number: "M02", student: @student1, level: @level, enrollment_status: @enrollment_status)
    @destroy_all << FactoryBot.create(:enrollment, enrollment_number: "M01", student: @student2, level: @level, enrollment_status: @enrollment_status)
    @destroy_all << FactoryBot.create(:enrollment, enrollment_number: "M03", student: @student3, level: @level, enrollment_status: @enrollment_status)
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
      expect(page).to have_content "Matrículas"
      expect(page.all("tr th").map(&:text)).to eq [
        "Número de Matrícula", "Nome do Aluno", "Tipo de Matrícula", "Nível", "Data de Admissão", "Desligamento", ""
      ]
    end

    it "should sort the list by name, asc" do
      expect(page.all("tr td.enrollment_number-column").map(&:text)).to eq ["M01", "M02", "M03"]
    end
  end

  describe "insert page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Adicionar"
    end

    it "should be able to insert and remove records" do
      # Insert record
      expect(page).to have_content "Adicionar Matrícula"
      within("#as_#{plural_name}-create--form") do
        fill_in "Número de Matrícula", with: "M04"
        find("#record_student_").click
        fill_in "Nome do Aluno", with: "Dan"
        sleep(0.5)
      end
      find("#record-select-students .current").click
      within("#as_#{plural_name}-create--form") do
        find(:select, "record_enrollment_status_").find(:option, text: @enrollment_status.name).select_option
        find(:select, "record_level_").find(:option, text: @level.name).select_option
      end
      click_button "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.enrollment_number-column", text: "M04")
      expect(page).to have_css("tr:nth-child(1) td.student-column", text: "Dani")

      # Remove inserted record
      expect(page.all("tr td.enrollment_number-column").map(&:text)).to eq ["M04", "M01", "M02", "M03"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.enrollment_number-column").map(&:text)).to eq ["M01", "M02", "M03"]
    end

    it "should have a month_year widget for admission_date" do
      field = "admission_date"
      expect(page.all("select#record_#{field}_2i option").map(&:text)).to eq ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
      expect(page.all("select#record_#{field}_1i option").map(&:text)).to include(1.years.ago.year.to_s, 1.years.since.year.to_s)
    end

    it "should have a record_select widget for research_area" do
      find("#record_research_area_").click
      sleep(0.2)
      expect(page).to have_selector("#record-select-research_areas", visible: true)
    end
  end

  describe "edit page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-edit-#{@record.id}-link").click
    end

    it "should be able to edit records" do
      within(".as_form") do
        fill_in "Número de Matrícula", with: "M05"
      end
      click_button "Atualizar"
      expect(page).to have_css("tr:nth-child(2) td.enrollment_number-column", text: "M05")
    end
  end
end
