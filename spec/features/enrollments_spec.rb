# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# ToDo: relationships

RSpec.describe "Enrollments features", type: :feature do
  let(:url_path) { "/enrollments" }
  let(:plural_name) { "enrollments" }
  let(:model) { Enrollment }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @role_student = FactoryBot.create(:role_aluno)
    @destroy_all << @user = create_confirmed_user(@role_adm)
    @destroy_all << @level1 = FactoryBot.create(:level, name: "Doutorado")
    @destroy_all << @level2 = FactoryBot.create(:level, name: "Mestrado")

    @destroy_all << @enrollment_status1 = FactoryBot.create(:enrollment_status, name: "Regular")
    @destroy_all << @enrollment_status2 = FactoryBot.create(:enrollment_status, name: "Avulso")
    @destroy_all << @student1 = FactoryBot.create(:student, name: "Ana", email: "ana.sapos@ic.uff.br")
    @destroy_all << @student2 = FactoryBot.create(:student, name: "Bia", email: "bia.sapos@ic.uff.br")
    @destroy_all << @student3 = FactoryBot.create(:student, name: "Carol")
    @destroy_all << @student4 = FactoryBot.create(:student, name: "Dani")

    @destroy_all << @user2 = create_confirmed_user(@role_student, "bia.sapos@ic.uff.br", "Bia", "A1b2c3d4!", student: @student2)

    @destroy_all << @role_professor = FactoryBot.create(:role_professor)
    @destroy_all << @user3 = create_confirmed_user(@role_professor, "joao.sapos@ic.uff.br", "João", "A1b2c3d4!")

    @destroy_all << @reasearch_area1 = FactoryBot.create(:research_area, name: "Ciência de Dados", code: "CD")

    @destroy_all << @phase2 = FactoryBot.create(:phase, name: "Pedido de Banca")
    @destroy_all << @phase3 = FactoryBot.create(:phase, name: "Exame de Qualificação")
    @destroy_all << FactoryBot.create(:phase_duration, level: @level2, phase: @phase2, deadline_months: 3, deadline_days: 0)
    @destroy_all << FactoryBot.create(:phase_duration, level: @level1, phase: @phase2, deadline_months: 3, deadline_days: 0)
    @destroy_all << FactoryBot.create(:phase_duration, level: @level1, phase: @phase3, deadline_months: 3, deadline_days: 0)

    @destroy_all << FactoryBot.create(:program_level)

    @destroy_all << @enrollment1 = FactoryBot.create(:enrollment, enrollment_number: "M02", student: @student1, level: @level2, enrollment_status: @enrollment_status1, admission_date: 3.years.ago.at_beginning_of_month.to_date)
    @destroy_all << @enrollment2 = FactoryBot.create(:enrollment, enrollment_number: "M01", student: @student2, level: @level2, enrollment_status: @enrollment_status2)
    @destroy_all << @enrollment3 = FactoryBot.create(:enrollment, enrollment_number: "M03", student: @student3, level: @level1, enrollment_status: @enrollment_status1, research_area: @reasearch_area1)
    @record = @enrollment1

    @destroy_all << @dismissal_reason1 = FactoryBot.create(:dismissal_reason, name: "Reprovado", thesis_judgement: "Reprovado")
    @destroy_all << FactoryBot.create(:dismissal, enrollment: @enrollment3, date: 1.day.ago, dismissal_reason: @dismissal_reason1)

    @destroy_all << @dismissal_reason2 = FactoryBot.create(:dismissal_reason, name: "Aprovado", thesis_judgement: DismissalReason::APPROVED)
    @destroy_all << FactoryBot.create(:dismissal, enrollment: @enrollment2, date: 1.day.ago, dismissal_reason: @dismissal_reason2)

    @destroy_all << @professor1 = FactoryBot.create(:professor, name: "Erica", cpf: "3")
    @destroy_all << FactoryBot.create(:advisement, enrollment: @enrollment1, professor: @professor1, main_advisor: true)
    @destroy_all << @sponsor1 = FactoryBot.create(:sponsor, name: "CNPq")
    @destroy_all << @scholarship_type2 = FactoryBot.create(:scholarship_type, name: "Projeto")
    @destroy_all << @scholarship3 = FactoryBot.create(:scholarship, scholarship_number: "B3", level: @level2, sponsor: @sponsor1, start_date: 3.years.ago, end_date: 1.year.from_now, scholarship_type: @scholarship_type2)
    @destroy_all << FactoryBot.create(:scholarship_duration, enrollment: @enrollment1, scholarship: @scholarship3, start_date: 2.years.ago, end_date: 1.months.from_now)

    @destroy_all << FactoryBot.create(:accomplishment, enrollment: @enrollment2, phase: @phase2, conclusion_date: 1.day.ago)

    @destroy_all << @course_type1 = FactoryBot.create(:course_type, name: "Obrigatória", has_score: true, schedulable: true, show_class_name: false, allow_multiple_classes: false, on_demand: false)
    @destroy_all << @course2 = FactoryBot.create(:course, name: "Algebra", code: "C1-old", credits: 4, workload: 60, course_type: @course_type1, available: false)
    @destroy_all << @course_class3 = FactoryBot.create(:course_class, name: "Algebra", course: @course2, professor: @professor1, year: 2021, semester: 1)
    @destroy_all << FactoryBot.create(:class_enrollment, enrollment: @enrollment2, course_class: @course_class3, grade: 80, situation: ClassEnrollment::APPROVED)

    @destroy_all << FactoryBot.create(:enrollment_hold, enrollment: @enrollment1, year: YearSemester.current.year, semester: YearSemester.current.semester, number_of_semesters: 1)

    @enrollment_status1.update!(user: true)
    @enrollment_status2.update!(user: true)
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    NotificationLog.destroy_all
    PhaseCompletion.destroy_all
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
      within("#as_#{plural_name}-create--form") { fill_in "Número de Matrícula", with: "M04" }
      fill_record_select("student_", "students", "Dan")
      within("#as_#{plural_name}-create--form") do
        find(:select, "record_enrollment_status_").find(:option, text: @enrollment_status1.name).select_option
        find(:select, "record_level_").find(:option, text: @level1.name).select_option
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
      expect_to_have_month_year_widget_i(page, "admission_date")
    end

    it "should have a record_select widget for research_area" do
      expect_to_have_record_select(page, "research_area_", "research_areas")
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

  describe "search page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Buscar"
    end

    it "should be able to search by enrollment_number" do
      fill_in "Número de Matrícula", with: "M02"
      click_button "Buscar"
      expect(page.all("tr td.enrollment_number-column").map(&:text)).to eq ["M02"]
    end

    it "should be able to search by student" do
      search_record_select("student", "students", "Ana")
      click_button "Buscar"
      expect(page.all("tr td.enrollment_number-column").map(&:text)).to eq ["M02"]
    end

    it "should be able to search by level" do
      expect(page.all("select#search_level option").map(&:text)).to eq ["", "Doutorado", "Mestrado"]
      find(:select, "search_level").find(:option, text: "Mestrado").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment_number-column").map(&:text)).to eq ["M01", "M02"]
    end

    it "should be able to search by enrollment_status" do
      expect(page.all("select#search_enrollment_status option").map(&:text)).to eq ["Selecione uma opção", "Avulso", "Regular"]
      find(:select, "search_enrollment_status").find(:option, text: "Avulso").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment_number-column").map(&:text)).to eq ["M01"]
    end

    it "should be able to search by admision_date" do
      select_month_year("search_admission_date", 3.years.ago.at_beginning_of_month.to_date)
      click_button "Buscar"
      expect(page.all("tr td.enrollment_number-column").map(&:text)).to eq ["M02"]
    end

    it "should be able to search by active" do
      expect(page.all("select#search_active option").map(&:text)).to eq ["Todas", "Ativas", "Inativas"]
      find(:select, "search_active").find(:option, text: "Inativas").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment_number-column").map(&:text)).to eq ["M01", "M03"]
    end

    it "should be able to search by scholarship_durations_active" do
      expect(page.all("select#search_scholarship_durations_active option").map(&:text)).to eq ["Selecione uma opção", "Sim", "Não"]
      find(:select, "search_scholarship_durations_active").find(:option, text: "Sim").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment_number-column").map(&:text)).to eq ["M02"]
    end

    it "should be able to search by advisor" do
      fill_in "Orientador", with: "Erica"
      click_button "Buscar"
      expect(page.all("tr td.enrollment_number-column").map(&:text)).to eq ["M02"]
    end

    it "should be able to search by phase" do
      expect(page.all("select[name=\"search[accomplishments][phase]\"] option").map(&:text)).to eq ["Selecione uma opção", "Todas", "Pedido de Banca", "Exame de Qualificação"]
      find(:css, "select[name=\"search[accomplishments][phase]\"]").find(:option, text: "Pedido de Banca").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment_number-column").map(&:text)).to eq ["M01"]
    end

    it "should be able to search by delayed_phase" do
      expect(page.all("select[name=\"search[delayed_phase][phase]\"] option").map(&:text)).to eq ["Selecione uma opção", "Alguma", "Pedido de Banca", "Exame de Qualificação"]
      find(:css, "select[name=\"search[delayed_phase][phase]\"]").find(:option, text: "Pedido de Banca").select_option
      click_button "Buscar"
      expect(page).to have_selector("tr td.enrollment_number-column", text: "M02")
      numbers = page.all("tr td.enrollment_number-column", minimum: 1).map(&:text)
      expect(numbers).to eq ["M02"]
    end

    it "should be able to search by course_class" do
      find(:select, "search_course_class_year_semester_course").find(:option, text: "Algebra").select_option
      click_button "Buscar"
      expect(page.all("tr td.enrollment_number-column").map(&:text)).to eq ["M01"]
    end

    it "should be able to search by research_area" do
      search_record_select("research_area", "research_areas", "Ciência de Dados")
      click_button "Buscar"
      expect(page.all("tr td.enrollment_number-column").map(&:text)).to eq ["M03"]
    end

    it "should be able to search for enrollment on hold" do
      find(:css, "input[name=\"search[enrollment_hold][hold]\"][type=\"checkbox\"]").set(true)
      click_button "Buscar"
      expect(page.all("tr td.enrollment_number-column").map(&:text)).to eq ["M02"]
    end
  end

  describe "generate report", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should download a pdf report of orientations" do
      click_link "Gerar relatório"

      wait_for_download
      expect(download).to match(/Relatório de Matrículas\.pdf/)
    end
  end

  describe "academic transcript report", js: true do
    context "when logged in as @user" do
      before(:each) do
        login_as(@user)
        visit url_path
      end

      it "should download an academic transcript" do
        find("#as_#{plural_name}-academic_transcript_pdf-#{@record.id}-link").click

        wait_for_download
        expect(download).to match(/Histórico Escolar - Ana\.pdf/)
      end
    end

    context "when logged in as professor" do
      before(:each) do
        login_as(@user3)
        visit url_path
      end
      context "when student is dismissed with title" do
        it "should be able to click the academic transcript link" do
          expect(page).to have_selector("#as_#{plural_name}-academic_transcript_pdf-#{@enrollment2.id}-link")
        end
      end

      context "when student is not dismissed with title" do
        it "should not be able to click the academic transcript link" do
          expect(page).not_to have_selector("#as_#{plural_name}-academic_transcript_pdf-#{@record.id}-link")
        end
      end
    end
  end

  describe "grades report", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should download grade report" do
      find("#as_#{plural_name}-grades_report_pdf-#{@record.id}-link").click

      wait_for_download
      expect(download).to match(/BOLETIM ESCOLAR _ PÓS-GRADUAÇÃO - Ana\.pdf/)
    end
  end

  describe "add users page", js: true do
    before(:each) do
      login_as(@user)
      visit url_path
      click_link "Adicionar usuários"
    end

    it "should show the numbers related to creating users" do
      expect(page).to have_content "Matrículas"
      expect(page).to have_field("field-enrollments", with: "3")
      expect(page).to have_content "que permitem usuários [?]"
      expect(page).to have_field("field-allowedenrollments", with: "3")
      expect(page).to have_content "Alunos"
      expect(page).to have_field("field-students", with: "3")
      expect(page).to have_content "vinculados a usuários"
      expect(page).to have_field("field-existingstudents", with: "1")
      expect(page).to have_content "sem email"
      expect(page).to have_field("field-noemail", with: "1")
    end

    it "should create users" do
      click_button "Adicionar"
      expect(User.all.size).to eq 4
      User.all.each do |user|
        next if [@user.id, @user2.id, @user3.id].include? user.id
        user.destroy
      end
    end
  end
end
