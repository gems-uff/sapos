# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Pendencies features", type: :feature do
  let(:url_path) { "/pendencies" }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @role_professor = FactoryBot.create(:role_professor)
    @destroy_all << @role_secretary = FactoryBot.create(:role_secretaria)
    @destroy_all << @user = create_confirmed_user([@role_adm])

    @destroy_all << CustomVariable.create(variable: :professor_login_can_post_grades, value: "yes")

    @destroy_all << @class_schedule = FactoryBot.create(:class_schedule, year: 0.years.ago.year, semester: YearSemester.current.semester, period_end: 5.days.ago)

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
    @destroy_all << @course_class2 = FactoryBot.create(:course_class, name: "Algebra", course: @course1, professor: @professor1, year: 0.years.ago.year, semester: YearSemester.current.semester)
    @destroy_all << @course_class3 = FactoryBot.create(:course_class, name: "Algebra", course: @course2, professor: @professor1, year: 2021, semester: 1)
    @destroy_all << @course_class4 = FactoryBot.create(:course_class, name: "Versionamento", course: @course3, professor: @professor2, year: 0.years.ago.year, semester: YearSemester.current.semester)
    @destroy_all << @course_class5 = FactoryBot.create(:course_class, name: "Defesa", course: @course4, professor: @professor3, year: 0.years.ago.year, semester: YearSemester.current.semester)
    @destroy_all << @course_class6 = FactoryBot.create(:course_class, name: "Mineração de Repositórios", course: @course5, professor: @professor2, year: 0.years.ago.year, semester: YearSemester.current.semester)
    @destroy_all << @course_class7 = FactoryBot.create(:course_class, name: "Pesquisa", course: @course6, professor: @professor3, year: 0.years.ago.year, semester: YearSemester.current.semester)
    @destroy_all << @course_class8 = FactoryBot.create(:course_class, name: "Programação", course: @course7, professor: @professor1, year: 0.years.ago.year, semester: YearSemester.current.semester)

    @destroy_all << FactoryBot.create(:advisement_authorization, professor: @professor1, level: @level2)
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
    @destroy_all << @class_enrollment5 = FactoryBot.create(:class_enrollment, enrollment: @enrollment3, course_class: @course_class2, situation: ClassEnrollment::REGISTERED)

    @destroy_all << @class_enrollment_request0 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request2_2021_1, course_class: @course_class3, class_enrollment: @class_enrollment1, action: ClassEnrollmentRequest::INSERT, status: ClassEnrollmentRequest::EFFECTED)
    @destroy_all << @class_enrollment_request1 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request1_2022_2, course_class: @course_class4, action: ClassEnrollmentRequest::INSERT, status: ClassEnrollmentRequest::VALID)
    @destroy_all << @class_enrollment_request2 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request1_2022_2, course_class: @course_class5, action: ClassEnrollmentRequest::INSERT, status: ClassEnrollmentRequest::REQUESTED)
    @destroy_all << @class_enrollment_request3 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request2_2022_2, course_class: @course_class4, action: ClassEnrollmentRequest::INSERT, status: ClassEnrollmentRequest::INVALID)
    @destroy_all << @class_enrollment_request4 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request3_2022_2, course_class: @course_class2, class_enrollment: @class_enrollment5, action: ClassEnrollmentRequest::REMOVE, status: ClassEnrollmentRequest::VALID)
    @destroy_all << @class_enrollment_request5 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request3_2022_2, course_class: @course_class4, action: ClassEnrollmentRequest::INSERT, status: ClassEnrollmentRequest::REQUESTED)
    @destroy_all << @professor_user = create_confirmed_user([@role_professor], "erica.sapos@ic.uff.br", "Erica", "A1b2c3d4!", professor: @professor1)
    @destroy_all << @secretary_user = create_confirmed_user([@role_secretary], "zenia.sapos@ic.uff.br", "Zenia", "A1b2c3d4!")
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

  describe "view pendencies as admin" do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should not show any pendencies" do
      expect(page).to have_content "Pendências"
      expect(page).to have_content "Nenhuma pendência encontrada."
    end
  end

  describe "view pendencies as professor", js: true do
    before(:each) do
      login_as(@professor_user)
      visit url_path
    end

    it "should show enrollment requests" do
      expect(page).to have_content "Pendências"
      expect(page).to have_content "Pedidos de Inscrição"
      expect(page).to have_selector(:css, ".enrollment_requests-view")
    end

    it "should show grade pendencies" do
      expect(page).to have_content "Turmas"
    end
  end

  describe "view pendencies as secretary", js: true do
    before(:each) do
      login_as(@secretary_user)
      visit url_path
    end

    it "should show enrollment requests" do
      expect(page).to have_content "Pendências"
      expect(page).to have_content "Pedidos de Inscrição em Disciplina"
      expect(page).to have_selector(:css, ".class_enrollment_requests-view")
    end

    it "should show grade pendencies" do
      expect(page).to have_content "Turmas"
    end
  end
end
