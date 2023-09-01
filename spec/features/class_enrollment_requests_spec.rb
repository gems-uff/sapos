# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "ClassEnrollmentRequests features", type: :feature do
  let(:url_path) { "/class_enrollment_requests" }
  let(:plural_name) { "class_enrollment_requests" }
  let(:model) { ClassEnrollmentRequest }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @user = create_confirmed_user(@role_adm)

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

    @destroy_all << @enrollment_request2_2021_1 = FactoryBot.create(:enrollment_request, enrollment: @enrollment2, year: 2021, semester: 1)
    @destroy_all << @enrollment_request1_2022_2 = FactoryBot.create(:enrollment_request, enrollment: @enrollment1, year: 2022, semester: 2)
    @destroy_all << @enrollment_request2_2022_2 = FactoryBot.create(:enrollment_request, enrollment: @enrollment2, year: 2022, semester: 2)
    @destroy_all << @enrollment_request3_2022_2 = FactoryBot.create(:enrollment_request, enrollment: @enrollment3, year: 2022, semester: 2)

    @destroy_all << @class_enrollment1 = FactoryBot.create(:class_enrollment, enrollment: @enrollment2, course_class: @course_class3, grade: 80, situation: ClassEnrollment::APPROVED)
    @destroy_all << @class_enrollment5 = FactoryBot.create(:class_enrollment, enrollment: @enrollment3, course_class: @course_class6, situation: ClassEnrollment::REGISTERED)


    @destroy_all << @record0 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request2_2021_1, course_class: @course_class3, class_enrollment: @class_enrollment1, action: ClassEnrollmentRequest::INSERT, status: ClassEnrollmentRequest::EFFECTED)
    @destroy_all << @record1 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request1_2022_2, course_class: @course_class4, action: ClassEnrollmentRequest::INSERT, status: ClassEnrollmentRequest::VALID)
    @destroy_all << @record2 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request1_2022_2, course_class: @course_class5, action: ClassEnrollmentRequest::INSERT, status: ClassEnrollmentRequest::REQUESTED)
    @destroy_all << @record3 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request2_2022_2, course_class: @course_class4, action: ClassEnrollmentRequest::INSERT, status: ClassEnrollmentRequest::INVALID)
    @destroy_all << @record4 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request3_2022_2, course_class: @course_class6, class_enrollment: @class_enrollment5, action: ClassEnrollmentRequest::REMOVE, status: ClassEnrollmentRequest::VALID)
    @destroy_all << @record5 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request3_2022_2, course_class: @course_class4, action: ClassEnrollmentRequest::INSERT, status: ClassEnrollmentRequest::REQUESTED)
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
      expect(page).to have_content "Pedidos de Inscrição em Disciplina"
      expect(page.all("tr th").map(&:text)).to eq [
        "Pedido de Inscrição", "Matrícula", "Turma", "Inscrição", "Alocações", "Professor", "Ação", "Situação", ""
      ]
    end

    it "should sort the list by enrollment, asc" do
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M01 - Ana", "M02 - Bia", "M02 - Bia", "M03 - Carol", "M03 - Carol"]
    end

    it "should not have insert link" do
      expect(page).not_to have_content "Adicionar"
    end

    it "should not have edit link" do
      expect(page).not_to have_selector("#as_#{plural_name}-edit-#{model.last.id}-link")
    end
  end

  describe "action links", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should be able to set status as valid" do
      expect(page).to have_selector("#as_#{plural_name}-list-#{@record2.id}-row td.status-column", text: "Solicitada")
      accept_confirm do
        find("#as_#{plural_name}-set_valid-#{@record2.id}-link").click
      end
      expect(page).to have_selector("#as_#{plural_name}-list-#{@record2.id}-row td.status-column", text: "Válida")
      @record2.status = "Solicitada"
      @record2.save!
    end

    it "should be able to set status as invalid" do
      expect(page).to have_selector("#as_#{plural_name}-list-#{@record2.id}-row td.status-column", text: "Solicitada")
      accept_confirm do
        find("#as_#{plural_name}-set_invalid-#{@record2.id}-link").click
      end
      expect(page).to have_selector("#as_#{plural_name}-list-#{@record2.id}-row td.status-column", text: "Inválida")
      @record2.status = "Solicitada"
      @record2.save!
    end

    it "should be able to set status as effected" do
      expect(page).to have_selector("#as_#{plural_name}-list-#{@record2.id}-row td.status-column", text: "Solicitada")
      accept_confirm do
        find("#as_#{plural_name}-set_effected-#{@record2.id}-link").click
      end
      expect(page).to have_selector("#as_#{plural_name}-list-#{@record2.id}-row td.status-column", text: "Efetivada")
      @record2.reload
      @record2.class_enrollment.delete
      @record2.status = "Solicitada"
      @record2.save!
    end

    it "should be able to set status as requested" do
      expect(page).to have_selector("#as_#{plural_name}-list-#{@record3.id}-row td.status-column", text: "Inválida")
      accept_confirm do
        find("#as_#{plural_name}-set_requested-#{@record3.id}-link").click
      end
      expect(page).to have_selector("#as_#{plural_name}-list-#{@record3.id}-row td.status-column", text: "Solicitada")
      @record3.status = "Inválida"
      @record3.save!
    end
  end

  describe "effect list", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Efetivar lista"
    end

    it "should show the number of requests that can be effected" do
      expect(page).to have_content "5 inscrições da lista podem ser efetivadas"
    end

    it "should effect all available requests" do
      click_button "Efetivar"
      @record0.reload
      expect(@record0.status).to eq "Efetivada"

      @record1.reload
      expect(@record1.status).to eq "Efetivada"
      expect(@record1.class_enrollment).not_to eq nil
      @record1.class_enrollment.delete
      @record1.status = ClassEnrollmentRequest::VALID
      @record1.save!

      @record2.reload
      expect(@record2.status).to eq "Efetivada"
      expect(@record2.class_enrollment).not_to eq nil
      @record2.class_enrollment.delete
      @record2.status = ClassEnrollmentRequest::VALID
      @record2.save!

      @record3.reload
      expect(@record3.status).to eq "Efetivada"
      expect(@record3.class_enrollment).not_to eq nil
      @record3.class_enrollment.delete
      @record3.status = ClassEnrollmentRequest::INVALID
      @record3.save!

      @record4.reload
      expect(@record4.status).to eq "Efetivada"
      expect(@record4.class_enrollment).to eq nil
      @destroy_all << @class_enrollment5 = FactoryBot.create(:class_enrollment, enrollment: @enrollment3, course_class: @course_class6, situation: ClassEnrollment::REGISTERED)
      @record4.class_enrollment = @class_enrollment5
      @record4.status = ClassEnrollmentRequest::VALID
      @record4.save!

      @record5.reload
      expect(@record5.status).to eq "Efetivada"
      expect(@record5.class_enrollment).not_to eq nil
      @record5.class_enrollment.delete
      @record5.status = ClassEnrollmentRequest::REQUESTED
      @record5.save!
    end
  end

  describe "help page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Ajuda"
    end

    it "should show the number of requests that can be effected" do
      expect(page).to have_content "Durante a inscrição online"
    end
  end

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by action" do
      expect(page.all("select#search_action option").map(&:text)).to eq ["Selecione uma opção", "Adição", "Remoção"]
      find(:select, "search_action").find(:option, text: "Remoção").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M03 - Carol"]
    end

    it "should be able to search by status" do
      expect(page.all("select#search_status option").map(&:text)).to eq ["Selecione uma opção", "Inválida", "Solicitada", "Válida", "Efetivada"]
      find(:select, "search_status").find(:option, text: "Inválida").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Bia"]
    end

    it "should be able to search by year" do
      expect(page.all("select#search_year option").map(&:text)).to eq [""] + YearSemester.selectable_years.map(&:to_s)
      find(:select, "search_year").find(:option, text: "2021").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Bia"]
    end

    it "should be able to search by semester" do
      expect(page.all("select#search_semester option").map(&:text)).to eq [""] + YearSemester::SEMESTERS.map(&:to_s)
      find(:select, "search_semester").find(:option, text: "1").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Bia"]
    end

    it "should be able to search by enrollment" do
      search_record_select("enrollment_", "enrollments", "M01")
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M01 - Ana"]
    end

    it "should be able to search by student" do
      search_record_select("student_", "students", "Ana")
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M01 - Ana"]
    end

    it "should be able to search by enrollment_level" do
      expect(page.all("select#search_enrollment_level option").map(&:text)).to eq ["Selecione uma opção", "Doutorado", "Mestrado"]
      find(:select, "search_enrollment_level").find(:option, text: "Mestrado").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M01 - Ana", "M02 - Bia", "M02 - Bia"]
    end

    it "should be able to search by enrollment_status" do
      expect(page.all("select#search_enrollment_status option").map(&:text)).to eq ["Selecione uma opção", "Regular", "Avulso"]
      find(:select, "search_enrollment_status").find(:option, text: "Avulso").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M02 - Bia", "M02 - Bia"]
    end

    it "should be able to search by admision_date" do
      select_month_year("search_admission_date", 3.years.ago.at_beginning_of_month.to_date)
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M01 - Ana"]
    end

    it "should be able to search by scholarship_durations_active" do
      expect(page.all("select#search_scholarship_durations_active option").map(&:text)).to eq ["Selecione uma opção", "Sim", "Não"]
      find(:select, "search_scholarship_durations_active").find(:option, text: "Sim").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M01 - Ana"]
    end

    it "should be able to search by has_advisor" do
      expect(page.all("select#search_has_advisor option").map(&:text)).to eq ["Selecione uma opção", "Sim", "Não"]
      find(:select, "search_has_advisor").find(:option, text: "Sim").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M01 - Ana"]
    end

    it "should be able to search by advisor" do
      search_record_select("advisor_", "professors", "Erica")
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M01 - Ana"]
    end

    it "should be able to search by course_class" do
      search_record_select("course_class", "course_classes", "Vers")
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M02 - Bia", "M03 - Carol"]
    end

    it "should be able to search by course_type" do
      expect(page.all("select#search_course_type option").map(&:text)).to eq ["Selecione uma opção", "Obrigatória", "Pesquisa", "Tópicos", "Defesa"]
      find(:select, "search_course_type").find(:option, text: "Defesa").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana"]
    end

    it "should be able to search by professor" do
      search_record_select("professor_", "professors", "Fiona")
      click_button "Buscar"
      expect(page.all("tr td.enrollment-column").map(&:text)).to eq ["M01 - Ana", "M02 - Bia", "M03 - Carol", "M03 - Carol"]
    end
  end
end
