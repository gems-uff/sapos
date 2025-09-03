# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "ClassEnrollments features", type: :feature do
  let(:url_path) { "/class_enrollments" }
  let(:plural_name) { "class_enrollments" }
  let(:model) { ClassEnrollment }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user([@role_adm])

    @destroy_all << @level1 = FactoryBot.create(:level, name: "Doutorado")
    @destroy_all << @level2 = FactoryBot.create(:level, name: "Mestrado")
    @destroy_all << @enrollment_status1 = FactoryBot.create(:enrollment_status, name: "Regular")
    @destroy_all << @enrollment_status2 = FactoryBot.create(:enrollment_status, name: "Avulso")

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
    @destroy_all << @enrollment1 = FactoryBot.create(:enrollment, enrollment_number: "M01", student: @student1, level: @level2, enrollment_status: @enrollment_status1, admission_date: 3.years.ago.at_beginning_of_month.to_date)
    @destroy_all << @enrollment2 = FactoryBot.create(:enrollment, enrollment_number: "M02", student: @student2, level: @level2, enrollment_status: @enrollment_status2)
    @destroy_all << @enrollment3 = FactoryBot.create(:enrollment, enrollment_number: "M03", student: @student3, level: @level1, enrollment_status: @enrollment_status1)
    @destroy_all << @enrollment4 = FactoryBot.create(:enrollment, enrollment_number: "M04", student: @student4, level: @level1, enrollment_status: @enrollment_status2)

    @destroy_all << @course_class1 = FactoryBot.create(:course_class, name: "Algebra", course: @course1, professor: @professor1, year: 2022, semester: 1)
    @destroy_all << @course_class2 = FactoryBot.create(:course_class, name: "Algebra", course: @course1, professor: @professor1, year: 2022, semester: 2)
    @destroy_all << @course_class3 = FactoryBot.create(:course_class, name: "Algebra", course: @course2, professor: @professor1, year: 2021, semester: 1)
    @destroy_all << @course_class4 = FactoryBot.create(:course_class, name: "Versionamento", course: @course3, professor: @professor2, year: 2022, semester: 2)
    @destroy_all << @course_class5 = FactoryBot.create(:course_class, name: "Defesa", course: @course4, professor: @professor3, year: 2022, semester: 2)
    @destroy_all << @course_class6 = FactoryBot.create(:course_class, name: "Mineração de Repositórios", course: @course5, professor: @professor2, year: 2022, semester: 2)
    @destroy_all << @course_class7 = FactoryBot.create(:course_class, name: "Pesquisa", course: @course6, professor: @professor3, year: 2022, semester: 2)
    @destroy_all << @course_class8 = FactoryBot.create(:course_class, name: "Programação", course: @course7, professor: @professor1, year: 2022, semester: 2)

    @destroy_all << FactoryBot.create(:advisement, enrollment: @enrollment1, professor: @professor1, main_advisor: true)
    @destroy_all << @sponsor1 = FactoryBot.create(:sponsor, name: "CNPq")
    @destroy_all << @scholarship_type2 = FactoryBot.create(:scholarship_type, name: "Projeto")
    @destroy_all << @scholarship3 = FactoryBot.create(:scholarship, scholarship_number: "B3", level: @level1, sponsor: @sponsor1, start_date: 3.years.ago, end_date: 1.year.from_now, scholarship_type: @scholarship_type2)
    @destroy_all << FactoryBot.create(:scholarship_duration, enrollment: @enrollment1, scholarship: @scholarship3, start_date: 2.years.ago, end_date: 1.months.from_now)

    @destroy_all << FactoryBot.create(:custom_variable, variable: "grade_of_disapproval_for_absence", value: "1")

    @destroy_all << FactoryBot.create(:class_enrollment, enrollment: @enrollment2, course_class: @course_class3, grade: 80, situation: ClassEnrollment::APPROVED)
    @destroy_all << @record = FactoryBot.create(:class_enrollment, enrollment: @enrollment1, course_class: @course_class4, grade: 80, situation: ClassEnrollment::APPROVED)
    @destroy_all << FactoryBot.create(:class_enrollment, enrollment: @enrollment1, course_class: @course_class5, situation: ClassEnrollment::APPROVED)
    @destroy_all << FactoryBot.create(:class_enrollment, enrollment: @enrollment2, course_class: @course_class4, grade: 10, disapproved_by_absence: true, situation: ClassEnrollment::DISAPPROVED)
    @destroy_all << FactoryBot.create(:class_enrollment, enrollment: @enrollment3, course_class: @course_class6, situation: ClassEnrollment::REGISTERED)
    @destroy_all << FactoryBot.create(:class_enrollment, enrollment: @enrollment3, course_class: @course_class4, grade: 70, situation: ClassEnrollment::APPROVED, grade_not_count_in_gpr: true, justification_grade_not_count_in_gpr: "Aproveitamento")
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
      expect(page).to have_content "Inscrições"
      expect(page.all("tr th").map(&:text)).to eq [
        "Matrícula", "Turma", "Situação", "Nota", "Reprovado por Falta", ""
      ]
    end

    it "should not have a sorting -- show in id order" do
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M01 - Ana", "M02 - Bia", "M02 - Bia", "M03 - Carol", "M03 - Carol"]
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
      expect(page).to have_content "Adicionar Inscrição"
      fill_record_select("enrollment_", "enrollments", "M04")
      page.send_keys :escape
      within("#as_#{plural_name}-create--form") do
        find(:select, "record_situation_").find(:option, text: "Incompleto").select_option
      end
      fill_record_select("course_class_", "course_classes", "Programação")
      click_button_and_wait "Salvar"
      expect(page).to have_css("tr:nth-child(1) td.enrollment-column", text: "M04 - Dani")

      # Remove inserted record
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M04 - Dani", "M01 - Ana", "M01 - Ana", "M02 - Bia", "M02 - Bia", "M03 - Carol", "M03 - Carol"]
      record = model.last
      accept_confirm { find("#as_#{plural_name}-destroy-#{record.id}-link").click }
      sleep(0.2)
      visit current_path
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M01 - Ana", "M02 - Bia", "M02 - Bia", "M03 - Carol", "M03 - Carol"]
    end

    it "should have a selection for semester" do
      page.send_keys :escape
      expect(page.all("select#record_situation_ option").map(&:text)).to eq ["Selecione"] + ClassEnrollment::SITUATIONS
    end

    it "should have a disapproved by absence widget" do
      page.send_keys :escape
      find(:css, "#record_disapproved_by_absence_").set(true)
      expect(page).to have_field("Nota", with: "1")
    end

    it "should have a justification_grade_not_count_in_gpr without a label" do
      page.send_keys :escape
      expect(page).to have_css("#record_justification_grade_not_count_in_gpr")
      expect(page).to have_css('label[for="record_justification_grade_not_count_in_gpr_"]', visible: false)
    end

    it "should have a record_select widget for enrollments" do
      expect_to_have_record_select(page, "enrollment_", "enrollments")
    end

    it "should have a record_select widget for course_classes" do
      page.send_keys :escape
      expect_to_have_record_select(page, "course_class_", "course_classes")
    end
  end

  describe "edit page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      find("#as_#{plural_name}-edit-#{@record.id}-link").click
    end

    it "should be able to edit student" do
      page.driver.browser.action.send_keys(:escape).perform
      within(".as_form") do
        fill_in "Nota", with: "6"
      end
      click_button_and_wait "Atualizar"
      expect(page).to have_css("td.grade_label-column", text: "6.0")
      @record.grade = 80
      @record.save!
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link_and_wait "Buscar"
    end

    it "should be able to search by situation" do
      expect(page.all("select#search_situation option").map(&:text)).to eq ["Selecione"] + ClassEnrollment::SITUATIONS
      find(:select, "search_situation").find(:option, text: "Incompleto").select_option
      click_button_and_wait "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M03 - Carol"]
    end

    it "should be able to search by year" do
      expect(page.all("select#search_year option").map(&:text)).to eq [""] + YearSemester.selectable_years.map(&:to_s)
      find(:select, "search_year").find(:option, text: "2021").select_option
      click_button_and_wait "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Bia"]
    end

    it "should be able to search by semester" do
      expect(page.all("select#search_semester option").map(&:text)).to eq [""] + YearSemester::SEMESTERS.map(&:to_s)
      find(:select, "search_semester").find(:option, text: "1").select_option
      click_button_and_wait "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Bia"]
    end

    it "should be able to search by enrollment" do
      search_record_select("enrollment_", "enrollments", "M01")
      click_button_and_wait "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M01 - Ana"]
    end

    it "should be able to search by student" do
      search_record_select("student_", "students", "Ana")
      click_button_and_wait "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M01 - Ana"]
    end

    it "should be able to search by enrollment_level" do
      expect(page.all("select#search_enrollment_level option").map(&:text)).to eq ["Selecione uma opção", "Doutorado", "Mestrado"]
      find(:select, "search_enrollment_level").find(:option, text: "Mestrado").select_option
      click_button_and_wait "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M01 - Ana", "M02 - Bia", "M02 - Bia"]
    end

    it "should be able to search by enrollment_status" do
      expect(page.all("select#search_enrollment_status option").map(&:text)).to eq ["Selecione uma opção", "Regular", "Avulso"]
      find(:select, "search_enrollment_status").find(:option, text: "Avulso").select_option
      click_button_and_wait "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Bia", "M02 - Bia"]
    end

    it "should be able to search by admision_date" do
      select_month_year("search_admission_date", 3.years.ago.at_beginning_of_month.to_date)
      click_button_and_wait "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M01 - Ana"]
    end

    it "should be able to search by scholarship_durations_active" do
      expect(page.all("select#search_scholarship_durations_active option").map(&:text)).to eq ["Selecione uma opção", "Sim", "Não"]
      find(:select, "search_scholarship_durations_active").find(:option, text: "Sim").select_option
      click_button_and_wait "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M01 - Ana"]
    end

    it "should be able to search by has_advisor" do
      expect(page.all("select#search_has_advisor option").map(&:text)).to eq ["Selecione uma opção", "Sim", "Não"]
      find(:select, "search_has_advisor").find(:option, text: "Sim").select_option
      click_button_and_wait "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M01 - Ana"]
    end

    it "should be able to search by advisor" do
      search_record_select("advisor_", "professors", "Erica")
      click_button_and_wait "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M01 - Ana"]
    end

    it "should be able to search by course_class" do
      search_record_select("course_class", "course_classes", "Vers")
      click_button_and_wait "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M02 - Bia", "M03 - Carol"]
    end

    it "should be able to search by course_type" do
      expect(page.all("select#search_course_type option").map(&:text)).to eq ["Selecione uma opção", "Obrigatória", "Pesquisa", "Tópicos", "Defesa"]
      find(:select, "search_course_type").find(:option, text: "Defesa").select_option
      click_button_and_wait "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana"]
    end

    it "should be able to search by professor" do
      search_record_select("professor_", "professors", "Fiona")
      click_button_and_wait "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M02 - Bia", "M03 - Carol", "M03 - Carol"]
    end

    it "should be able to search by disapproved_by_absence" do
      expect(page.all("select#search_disapproved_by_absence option").map(&:text)).to eq ["Selecione uma opção", "Sim", "Não"]
      find(:select, "search_disapproved_by_absence").find(:option, text: "Sim").select_option
      click_button_and_wait "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Bia"]
    end
  end
end
