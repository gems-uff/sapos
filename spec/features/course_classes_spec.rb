# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# ToDo: allocations

RSpec.describe "CourseClasses features", type: :feature do
  let(:url_path) { "/course_classes" }
  let(:plural_name) { "course_classes" }
  let(:model) { CourseClass }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user(@role_adm)

    @destroy_all << @level1 = FactoryBot.create(:level, name: "Doutorado")
    @destroy_all << @level2 = FactoryBot.create(:level, name: "Mestrado")
    @destroy_all << @enrollment_status = FactoryBot.create(:enrollment_status, name: "Regular")

    @destroy_all << @course_type1 = FactoryBot.create(:course_type, name: "Obrigatória", has_score: true, schedulable: true, show_class_name: false, allow_multiple_classes: false, on_demand: false)
    @destroy_all << @course_type2 = FactoryBot.create(:course_type, name: "Pesquisa", has_score: false, schedulable: true, show_class_name: false, allow_multiple_classes: true, on_demand: true)
    @destroy_all << @course_type3 = FactoryBot.create(:course_type, name: "Tópicos", has_score: true, schedulable: true, show_class_name: true, allow_multiple_classes: true, on_demand: false)
    @destroy_all << @course_type4 = FactoryBot.create(:course_type, name: "Defesa", has_score: false, schedulable: false, show_class_name: false, allow_multiple_classes: false, on_demand: false)

    @destroy_all << @research_area1 = FactoryBot.create(:research_area, name: "Ciência de Dados", code: "CD")
    @destroy_all << @research_area2 = FactoryBot.create(:research_area, name: "Sistemas de Computação", code: "SC")
    @destroy_all << @research_area3 = FactoryBot.create(:research_area, name: "Engenharia de Software", code: "ES")

    @destroy_all << @course1 = FactoryBot.create(:course, name: "Algebra", code: "C1", credits: 4, workload: 60, course_type: @course_type1, available: true)
    @destroy_all << @course2 = FactoryBot.create(:course, name: "Algebra", code: "C1-old", credits: 4, workload: 60, course_type: @course_type1, available: false)
    @destroy_all << @course3 = FactoryBot.create(:course, name: "Versionamento", code: "C2", credits: 4, workload: 60, course_type: @course_type1, available: true)
    @destroy_all << @course4 = FactoryBot.create(:course, name: "Defesa", code: "C3", credits: 72, workload: 1080, course_type: @course_type4, available: true)
    @destroy_all << @course5 = FactoryBot.create(:course, name: "Tópicos em ES", code: "C4", credits: 4, workload: 60, course_type: @course_type3, available: true)
    @destroy_all << @course6 = FactoryBot.create(:course, name: "Pesquisa", code: "C5", credits: 0, workload: 0, course_type: @course_type2, available: true)
    @destroy_all << @course7 = FactoryBot.create(:course, name: "Programação", code: "C6", credits: 4, workload: 60, course_type: @course_type1, available: true)

    @destroy_all << FactoryBot.create(:course_research_area, course: @course3, research_area: @research_area3)
    @destroy_all << FactoryBot.create(:course_research_area, course: @course5, research_area: @research_area3)

    @destroy_all << @professor1 = FactoryBot.create(:professor, name: "Erica", cpf: "3")
    @destroy_all << @professor2 = FactoryBot.create(:professor, name: "Fiona", cpf: "2")
    @destroy_all << @professor3 = FactoryBot.create(:professor, name: "Gi", cpf: "1")
    @destroy_all << @professor4 = FactoryBot.create(:professor, name: "Helena", cpf: "4")

    @destroy_all << @student1 = FactoryBot.create(:student, name: "Ana")
    @destroy_all << @student2 = FactoryBot.create(:student, name: "Bia")
    @destroy_all << @student3 = FactoryBot.create(:student, name: "Carol")
    @destroy_all << @student4 = FactoryBot.create(:student, name: "Dani")
    @destroy_all << @enrollment1 = FactoryBot.create(:enrollment, enrollment_number: "M01", student: @student1, level: @level2, enrollment_status: @enrollment_status, admission_date: 3.years.ago.to_date)
    @destroy_all << @enrollment2 = FactoryBot.create(:enrollment, enrollment_number: "M02", student: @student2, level: @level2, enrollment_status: @enrollment_status)
    @destroy_all << @enrollment3 = FactoryBot.create(:enrollment, enrollment_number: "M03", student: @student3, level: @level1, enrollment_status: @enrollment_status)
    @destroy_all << @enrollment4 = FactoryBot.create(:enrollment, enrollment_number: "M04", student: @student4, level: @level1, enrollment_status: @enrollment_status)

    @destroy_all << FactoryBot.create(:course_class, name: "Algebra", course: @course1, professor: @professor1, year: 2022, semester: 1)
    @destroy_all << FactoryBot.create(:course_class, name: "Algebra", course: @course1, professor: @professor1, year: 2022, semester: 2)
    @destroy_all << FactoryBot.create(:course_class, name: "Algebra", course: @course2, professor: @professor1, year: 2021, semester: 2)
    @destroy_all << @course_class4 = FactoryBot.create(:course_class, name: "Versionamento", course: @course3, professor: @professor2, year: 2022, semester: 2)
    @destroy_all << @record = FactoryBot.create(:course_class, name: "Defesa", course: @course4, professor: @professor3, year: 2022, semester: 2)
    @destroy_all << FactoryBot.create(:course_class, name: "Mineração de Repositórios", course: @course5, professor: @professor2, year: 2022, semester: 2)
    @destroy_all << FactoryBot.create(:course_class, name: "Pesquisa", course: @course6, professor: @professor3, year: 2022, semester: 2)

    @destroy_all << FactoryBot.create(:class_enrollment, enrollment: @enrollment1, course_class: @course_class4)
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
      expect(page).to have_content "Turmas"
      expect(page.all("tr th").map(&:text)).to eq [
        "Nome", "Disciplina", "Professor", "Ano", "Semestre", "Alunos Inscritos", ""
      ]
    end

    it "should sort the list by name, asc" do
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Algebra", "Algebra", "Algebra", "Defesa", "Mineração de Repositórios", "Pesquisa", "Versionamento"]
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
      expect(page).to have_content "Adicionar Turma"
      within("#as_#{plural_name}-create--form") do
        fill_in "Nome", with: "Programação"
        find(:select, "record_year_").find(:option, text: YearSemester.current.year.to_s).select_option
        find(:select, "record_semester_").find(:option, text: YearSemester.current.semester.to_s).select_option
      end
      fill_record_select("professor_", "professors", "Helena")
      fill_record_select("course_", "courses", "Programação")
      click_button_and_wait "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.name-column", text: "Programação")

      # Remove inserted record
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Programação", "Algebra", "Algebra", "Algebra", "Defesa", "Mineração de Repositórios", "Pesquisa", "Versionamento"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Algebra", "Algebra", "Algebra", "Defesa", "Mineração de Repositórios", "Pesquisa", "Versionamento"]
    end

    it "should have a selection for semester" do
      expect(page.all("select#record_semester_ option").map(&:text)).to eq [""] + YearSemester::SEMESTERS.map(&:to_s)
    end

    it "should have a selection for year" do
      expect(page.all("select#record_year_ option").map(&:text)).to eq [""] + YearSemester.selectable_years.map(&:to_s)
    end

    it "should have a record_select widget for professors" do
      expect_to_have_record_select(page, "professor_", "professors")
    end

    it "should have a record_select widget for courses" do
      expect_to_have_record_select(page, "course_", "courses")
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
        fill_in "Nome", with: "Teste"
      end
      click_button_and_wait "Atualizar"
      expect(page).to have_css("td.name-column", text: "Teste")
      @record.name = "Defesa"
      @record.save!
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by name" do
      fill_in "Nome", with: "Ver"
      click_button_and_wait "Buscar"
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Versionamento"]
    end

    it "should be able to search by year" do
      find(:select, "search_year").find(:option, text: "2021").select_option
      click_button_and_wait "Buscar"
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Algebra"]
    end

    it "should be able to search by semester" do
      find(:select, "search_semester").find(:option, text: "1").select_option
      click_button_and_wait "Buscar"
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Algebra"]
    end

    it "should be able to search by professor" do
      fill_in "Professor", with: "Fiona"
      click_button_and_wait "Buscar"
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Mineração de Repositórios", "Versionamento"]
    end

    it "should be able to search by course" do
      fill_in "Disciplina", with: "Vers"
      click_button_and_wait "Buscar"
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Versionamento"]
    end

    it "should be able to search by enrollment" do
      search_record_select("enrollments", "enrollments", "M01")
      click_button_and_wait "Buscar"
      expect(page.all("tr td.name-column").map(&:text)).to eq ["Versionamento"]
    end
  end

  describe "class schedule report", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should show an error when year/semester is not selected" do
      click_link "Quadro de Horários"
      expect(page).to have_content "Selecione Ano/Semestre na busca!"
    end

    it "should generate report when year/semester is selected" do
      click_link "Buscar"
      find(:select, "search_year").find(:option, text: "2022").select_option
      find(:select, "search_semester").find(:option, text: "2").select_option
      click_button_and_wait "Buscar"

      click_link "Quadro de Horários"
      wait_for_download
      expect(download).to match(/QUADRO DE HORÁRIOS \(2022_2\)\.pdf/)
    end
  end

  describe "course class report as pdf", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should download a summary as pdf for a record" do
      find("#as_#{plural_name}-summary_pdf-#{@record.id}-link").click

      wait_for_download
      expect(download).to match(/Resumo Semestral - Defesa\.pdf/)
    end
  end

  describe "course class report as xlsx", js: true do
    before(:each) do
        login_as(@user)
        visit url_path
      end
    it "should download a summary as xlsx for a record" do
      find("#as_#{plural_name}-summary_xls-#{@record.id}-link").click

      wait_for_download
      expect(download).to match(/Resumo Semestral - Defesa\(2022-2\)\.xlsx/)
    end
  end
end
