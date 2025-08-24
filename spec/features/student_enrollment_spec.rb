# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "StudentEnrollment features", type: :feature, js: true do
  let(:url_path) { "/pendencies" }
  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @role_professor = FactoryBot.create(:role_professor)
    @destroy_all << @role_student = FactoryBot.create(:role_aluno)
    @destroy_all << @user = create_confirmed_user([@role_adm])

    @destroy_all << @level1 = FactoryBot.create(:level, name: "Doutorado")
    @destroy_all << @level2 = FactoryBot.create(:level, name: "Mestrado")
    @destroy_all << @enrollment_status1 = FactoryBot.create(:enrollment_status, name: "Regular")
    @destroy_all << @enrollment_status2 = FactoryBot.create(:enrollment_status, name: "Avulso")

    @destroy_all << @phase2 = FactoryBot.create(:phase, name: "Pedido de Banca")
    @destroy_all << @phase3 = FactoryBot.create(:phase, name: "Exame de Qualificação")
    @destroy_all << FactoryBot.create(:phase_duration, level: @level2, phase: @phase2, deadline_months: 3, deadline_days: 0)
    @destroy_all << FactoryBot.create(:phase_duration, level: @level1, phase: @phase2, deadline_months: 3, deadline_days: 0)
    @destroy_all << FactoryBot.create(:phase_duration, level: @level1, phase: @phase3, deadline_months: 3, deadline_days: 0)

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

    @destroy_all << @institution = FactoryBot.create(:institution, name: "UFF")

    @destroy_all << @affiliation1 = FactoryBot.create(:affiliation, institution: @institution, professor: @professor1, start_date: 3.year.ago, end_date: nil)
    @destroy_all << @affiliation2 = FactoryBot.create(:affiliation, institution: @institution, professor: @professor2, start_date: 3.year.ago, end_date: nil)
    @destroy_all << @affiliation3 = FactoryBot.create(:affiliation, institution: @institution, professor: @professor3, start_date: 3.year.ago, end_date: nil)

    @destroy_all << FactoryBot.create(:advisement_authorization, professor: @professor1, level: @level1)
    @destroy_all << FactoryBot.create(:advisement_authorization, professor: @professor1, level: @level2)
    @destroy_all << FactoryBot.create(:advisement_authorization, professor: @professor2, level: @level1)
    @destroy_all << FactoryBot.create(:advisement_authorization, professor: @professor2, level: @level2)
    @destroy_all << FactoryBot.create(:advisement_authorization, professor: @professor3, level: @level1)
    @destroy_all << FactoryBot.create(:advisement_authorization, professor: @professor3, level: @level2)

    @destroy_all << @student1 = FactoryBot.create(:student, name: "Ana")
    @destroy_all << @enrollment1 = FactoryBot.create(:enrollment, enrollment_number: "M01", student: @student1,
                                                     level: @level2, enrollment_status: @enrollment_status1,
                                                     admission_date: 3.years.ago.at_beginning_of_month.to_date,
                                                     research_area: @research_area1, thesis_defense_date: Time.now)
    @destroy_all << @enrollment2 = FactoryBot.create(:enrollment, enrollment_number: "M02", student: @student1, level: @level2, enrollment_status: @enrollment_status1)
    @destroy_all << @enrollment3 = FactoryBot.create(:enrollment, enrollment_number: "D01", student: @student1, level: @level1, enrollment_status: @enrollment_status1)
    @destroy_all << @enrollment4 = FactoryBot.create(:enrollment, enrollment_number: "D02", student: @student1, level: @level1, enrollment_status: @enrollment_status1)

    @destroy_all << @course_class1 = FactoryBot.create(:course_class, name: "Algebra", course: @course1, professor: @professor1, year: 2022, semester: 1)
    @destroy_all << @course_class2 = FactoryBot.create(:course_class, name: "Algebra", course: @course1, professor: @professor1, year: 2022, semester: 2)
    @destroy_all << @course_class3 = FactoryBot.create(:course_class, name: "Algebra", course: @course2, professor: @professor1, year: 2021, semester: 1)
    @destroy_all << @course_class4 = FactoryBot.create(:course_class, name: "Versionamento", course: @course3, professor: @professor2, year: 2022, semester: 2)
    @destroy_all << @course_class5 = FactoryBot.create(:course_class, name: "Defesa", course: @course4, professor: @professor3, year: 2022, semester: 2)
    @destroy_all << @course_class6 = FactoryBot.create(:course_class, name: "Mineração de Repositórios", course: @course5, professor: @professor2, year: 2022, semester: 2)
    @destroy_all << @course_class7 = FactoryBot.create(:course_class, name: "Pesquisa", course: @course6, professor: @professor3, year: 2022, semester: 2)
    @destroy_all << @course_class8 = FactoryBot.create(:course_class, name: "Programação", course: @course7, professor: @professor1, year: 2022, semester: 2)

    @destroy_all << FactoryBot.create(:allocation, course_class: @course_class2, day: "Segunda", start_time: 11, end_time: 13)
    @destroy_all << FactoryBot.create(:allocation, course_class: @course_class2, day: "Segunda", start_time: 14, end_time: 16)
    @destroy_all << @record = FactoryBot.create(:allocation, course_class: @course_class4, day: "Segunda", start_time: 11, end_time: 13)
    @destroy_all << FactoryBot.create(:allocation, course_class: @course_class4, day: "Quarta", start_time: 11, end_time: 13)
    @destroy_all << FactoryBot.create(:allocation, course_class: @course_class6, day: "Terça", start_time: 11, end_time: 13)
    @destroy_all << FactoryBot.create(:allocation, course_class: @course_class6, day: "Quinta", start_time: 11, end_time: 13)
    @destroy_all << FactoryBot.create(:allocation, course_class: @course_class8, day: "Quarta", start_time: 9, end_time: 11)
    @destroy_all << FactoryBot.create(:allocation, course_class: @course_class8, day: "Sexta", start_time: 9, end_time: 11)

    # Dismissal
    @destroy_all << @dismissal_reason1 = FactoryBot.create(:dismissal_reason, name: "Reprovado", thesis_judgement: "Reprovado")
    @destroy_all << @dismissal_reason2 = FactoryBot.create(:dismissal_reason, name: "Titulação", thesis_judgement: "Aprovado", show_advisor_name: true)
    @destroy_all << FactoryBot.create(:dismissal, enrollment: @enrollment1, date: 1.year.ago.at_beginning_of_month, dismissal_reason: @dismissal_reason2)
    @destroy_all << FactoryBot.create(:thesis_defense_committee_participation, enrollment: @enrollment1, professor: @professor1)
    @destroy_all << FactoryBot.create(:thesis_defense_committee_participation, enrollment: @enrollment1, professor: @professor2)
    @destroy_all << FactoryBot.create(:thesis_defense_committee_participation, enrollment: @enrollment1, professor: @professor3)

    # Class enrollments
    @destroy_all << FactoryBot.create(:class_enrollment, enrollment: @enrollment1, course_class: @course_class3, grade: 80, situation: ClassEnrollment::APPROVED)
    @destroy_all << FactoryBot.create(:class_enrollment, enrollment: @enrollment1, course_class: @course_class4, grade: 80, situation: ClassEnrollment::APPROVED, grade_not_count_in_gpr: true, justification_grade_not_count_in_gpr: "Aproveitamento")
    @destroy_all << FactoryBot.create(:class_enrollment, enrollment: @enrollment1, course_class: @course_class5, situation: ClassEnrollment::APPROVED)
    @destroy_all << FactoryBot.create(:class_enrollment, enrollment: @enrollment1, course_class: @course_class7, situation: ClassEnrollment::APPROVED)
    @destroy_all << FactoryBot.create(:class_enrollment, enrollment: @enrollment1, course_class: @course_class1, grade: 0, disapproved_by_absence: true, situation: ClassEnrollment::DISAPPROVED)

    # Advisements
    @destroy_all << FactoryBot.create(:advisement, enrollment: @enrollment1, professor: @professor1, main_advisor: true)
    @destroy_all << FactoryBot.create(:advisement, enrollment: @enrollment1, professor: @professor2, main_advisor: false)

    # Phases
    @destroy_all << FactoryBot.create(:accomplishment, enrollment: @enrollment1, phase: @phase2, conclusion_date: 14.months.ago.at_beginning_of_month)

    # Deferrals
    @destroy_all << @deferral_type2 = FactoryBot.create(:deferral_type, name: "Regular", phase: @phase2)
    @destroy_all << FactoryBot.create(:deferral, deferral_type: @deferral_type2, enrollment: @enrollment1, approval_date: 15.months.ago.at_beginning_of_month)

    # Holds
    @destroy_all << @record = FactoryBot.create(:enrollment_hold, enrollment: @enrollment1, year: 3.years.ago.year, semester: 2, number_of_semesters: 1)

    # Scholarships
    @destroy_all << @sponsor1 = FactoryBot.create(:sponsor, name: "CNPq")
    @destroy_all << @scholarship_type2 = FactoryBot.create(:scholarship_type, name: "Projeto")
    @destroy_all << @scholarship3 = FactoryBot.create(:scholarship, scholarship_number: "B3", level: @level1, sponsor: @sponsor1, start_date: 3.years.ago, end_date: 1.year.from_now, scholarship_type: @scholarship_type2)
    @destroy_all << FactoryBot.create(:scholarship_duration, enrollment: @enrollment1, scholarship: @scholarship3, start_date: 2.years.ago, end_date: 13.months.ago.end_of_month)

    # Class Schedule
    @destroy_all << @class_schedule = FactoryBot.create(
      :class_schedule, year: 2022, semester: 2,
      enrollment_start: DateTime.new(2022, 8, 8, 0, 0, 0, Time.zone.formatted_offset),
      enrollment_end: DateTime.new(2022, 8, 11, 23, 59, 59, Time.zone.formatted_offset),
      period_start: DateTime.new(2022, 8, 22, 0, 0, 0, Time.zone.formatted_offset),
      enrollment_insert: DateTime.new(2022, 9, 6, 23, 59, 59, Time.zone.formatted_offset),
      enrollment_remove: DateTime.new(2022, 9, 21, 23, 59, 59, Time.zone.formatted_offset),
      period_end: DateTime.new(2022, 11, 22, 0, 0, 0, Time.zone.formatted_offset),
      grades_deadline: DateTime.new(2022, 11, 29, 0, 0, 0, Time.zone.formatted_offset)
    )

    # Enrollment request
    @destroy_all << @enrollment_request3_2022_2 = FactoryBot.create(:enrollment_request, enrollment: @enrollment3, year: 2022, semester: 2, student_view_at: 3.days.ago)
    @destroy_all << @enrollment_request4_2022_2 = FactoryBot.create(:enrollment_request, enrollment: @enrollment4, year: 2022, semester: 2, student_view_at: 3.days.ago)

    # Class enrollment request
    @destroy_all << @class_enrollment1 = FactoryBot.create(:class_enrollment, enrollment: @enrollment3, course_class: @course_class4, situation: ClassEnrollment:: REGISTERED)
    @destroy_all << @class_enrollment2 = FactoryBot.create(:class_enrollment, enrollment: @enrollment3, course_class: @course_class1, grade: 80, situation: ClassEnrollment::APPROVED)
    @destroy_all << @class_enrollment3 = FactoryBot.create(:class_enrollment, enrollment: @enrollment3, course_class: @course_class8, situation: ClassEnrollment:: REGISTERED)
    @destroy_all << @class_enrollment_request0 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request3_2022_2, course_class: @course_class4, class_enrollment: @class_enrollment1, action: ClassEnrollmentRequest::INSERT, status: ClassEnrollmentRequest::EFFECTED)
    @destroy_all << @class_enrollment_request_4_0 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request4_2022_2, course_class: @course_class4, action: ClassEnrollmentRequest::INSERT, status: ClassEnrollmentRequest::REQUESTED)
    @destroy_all << @class_enrollment_request1 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request3_2022_2, course_class: @course_class6, action: ClassEnrollmentRequest::INSERT, status: ClassEnrollmentRequest::VALID)
    @destroy_all << @class_enrollment_request2 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request3_2022_2, course_class: @course_class5, action: ClassEnrollmentRequest::INSERT, status: ClassEnrollmentRequest::INVALID)
    @destroy_all << @class_enrollment_request3 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request3_2022_2, course_class: @course_class7, action: ClassEnrollmentRequest::INSERT, status: ClassEnrollmentRequest::REQUESTED)
    @destroy_all << @class_enrollment_request4 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request3_2022_2, course_class: @course_class8, class_enrollment: @class_enrollment3, action: ClassEnrollmentRequest::REMOVE, status: ClassEnrollmentRequest::VALID)

    @destroy_all << @enrollment_request_comment = FactoryBot.create(:enrollment_request_comment, enrollment_request: @enrollment_request3_2022_2, user: @user, message: "Some comment")

    @destroy_all << @student_user = create_confirmed_user([@role_student], "ana.sapos@ic.uff.br", "Ana", "A1b2c3d4!", student: @student1)

    @enrollment_status1.update!(user: true)
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @destroy_all.each(&:delete)
    @destroy_all.clear
    PhaseCompletion.destroy_all
    UserRole.delete_all
  end

  describe "show" do
    describe "complete" do
      before(:each) do
        login_as(@student_user)
        visit student_enrollment_path(@enrollment1.id)
      end

      it "should show enrollment info" do
        date = 3.years.ago.at_beginning_of_month.to_date
        expect(page).to have_content "Matrícula de Mestrado M01 (Desligada)"
        expect(page).to have_content "Ana"
        expect(page).to have_content "Área de Concentração: Ciência de Dados"
        expect(page).to have_content "#{I18n.l(date, format: "%B-%Y")}"
      end

      it "should show dimissal" do
        within(".dismissal-show-box") do
          expect(page).to have_content "Desligamento"
          date = 1.year.ago.at_beginning_of_month.to_date
          expect(page).to have_content "Data #{I18n.l(date, format: "%B-%Y")}"
          expect(page).to have_content "Motivo do Desligamento Titulação"
          expect(page).to have_content "Banca Avaliadora"
          expect(page.all("tr th").map(&:text)).to eq [
            "Nome", "Instituição"
          ]
          expect(page.all("tbody tr").size).to eq 3
          expect(page).to have_content "UFF"
        end
      end

      it "should show class_enrollments" do
        within(".class-enrollments-show-box") do
          expect(page).to have_content "Disciplinas"
          expect(page.all("table:nth-of-type(1) tr th").map(&:text)).to eq [
            "Semestre", "Disciplina", "Situação", "Nota", "Reprovado por Falta"
          ]
          expect(page.all("table:nth-of-type(1) tbody tr").size).to eq 5
          expect(page).to have_content "Disciplinas que não contabilizam nota:"
          expect(page.all("table:nth-of-type(2) tr th").map(&:text)).to eq [
            "Semestre", "Disciplina", "Justificativa para não contabilizar nota"
          ]
          expect(page.all("table:nth-of-type(2) tbody tr").size).to eq 1
        end
      end

      it "should show advisements" do
        within(".advisements-show-box") do
          expect(page).to have_content "Orientações"
          expect(page.all("table:nth-of-type(1) tr th").map(&:text)).to eq [
            "Orientador",
          ]
          expect(page.all("table:nth-of-type(1) tbody tr").size).to eq 2
        end
      end

      it "should show phases" do
        within(".phases-show-box") do
          expect(page).to have_content "Etapas"
          expect(page.all("table:nth-of-type(1) tr th").map(&:text)).to eq [
            "Etapa", "Validade", "Conclusão"
          ]
          expect(page.all("table:nth-of-type(1) tbody tr").size).to eq 2
        end
      end

      it "should show deferrals" do
        within(".deferrals-show-box") do
          expect(page).to have_content "Prorrogações"
          expect(page.all("table:nth-of-type(1) tr th").map(&:text)).to eq [
            "Data de aprovação", "Tipo de prorrogação"
          ]
          expect(page.all("table:nth-of-type(1) tbody tr").size).to eq 1
        end
      end

      it "should show holds" do
        within(".holds-show-box") do
          expect(page).to have_content "Trancamentos"
          expect(page.all("table:nth-of-type(1) tr th").map(&:text)).to eq [
            "Semestre", "Número de Semestres"
          ]
          expect(page.all("table:nth-of-type(1) tbody tr").size).to eq 1
        end
      end

      it "should show scholarships" do
        within(".scholarships-show-box") do
          expect(page).to have_content "Bolsas"
          expect(page.all("table:nth-of-type(1) tr th").map(&:text)).to eq [
            "Número da Bolsa", "Agência", "Data de Início", "Data Limite de Concessão", "Data de Encerramento"
          ]
          expect(page.all("table:nth-of-type(1) tbody tr").size).to eq 1
        end
      end
    end

    describe "with new enrollment request option" do
      before(:all) do
        @class_schedule.enrollment_start = 3.days.ago
        @class_schedule.enrollment_end = 3.days.from_now
        @class_schedule.save!
      end
      after(:all) do
        @class_schedule.enrollment_start = DateTime.new(2022, 8, 8, 0, 0, 0, Time.zone.formatted_offset)
        @class_schedule.enrollment_end = DateTime.new(2022, 8, 11, 23, 59, 59, Time.zone.formatted_offset)
        @class_schedule.save!
      end

      before(:each) do
        login_as(@student_user)
        visit student_enrollment_path(@enrollment2.id)
      end

      it "should show enroll now option" do
        expect(page).to have_content "Inscrições em disciplinas do semestre 2022.2 estão abertas!"
        click_link_and_wait "Clique aqui para fazer um pedido de inscrição."
        expect(page).to have_current_path("/enrollment/#{@enrollment2.id}/enroll/2022-2")
      end
    end

    describe "with edit enrollment request option" do
      before(:all) do
        @class_schedule.enrollment_start = 3.days.ago
        @class_schedule.enrollment_end = 3.days.from_now
        @class_schedule.save!
      end
      after(:all) do
        @class_schedule.enrollment_start = DateTime.new(2022, 8, 8, 0, 0, 0, Time.zone.formatted_offset)
        @class_schedule.enrollment_end = DateTime.new(2022, 8, 11, 23, 59, 59, Time.zone.formatted_offset)
        @enrollment_request3_2022_2.student_view_at = 3.days.ago
        @class_schedule.save!
      end

      before(:each) do
        login_as(@student_user)
      end

      describe "invalid enrollment request" do
        before(:each) do
          visit student_enrollment_path(@enrollment3.id)
        end

        it "should show edit option" do
          expect(page).to have_content "Inscrições em disciplinas do semestre 2022.2 estão abertas!"
          expect(page).to have_content "Seu pedido de inscrição foi marcado como inválido"
          expect(page).to have_content "1 mensagem não lida"
          click_link_and_wait "Clique aqui para editar"
          expect(page).to have_current_path("/enrollment/#{@enrollment3.id}/enroll/2022-2")
        end
      end

      describe "valid enrollment request" do
        before(:all) do
          @class_enrollment_request2.update!(status: ClassEnrollmentRequest::VALID)
          @class_enrollment_request3.update!(status: ClassEnrollmentRequest::VALID)
        end
        after(:all) do
          @class_enrollment_request2.update!(status: ClassEnrollmentRequest::INVALID)
          @class_enrollment_request3.update!(status: ClassEnrollmentRequest::REQUESTED)
        end

        before(:each) do
          visit student_enrollment_path(@enrollment3.id)
        end

        it "should show edit option" do
          expect(page).to have_content "Inscrições em disciplinas do semestre 2022.2 estão abertas!"
          expect(page).to have_content "Seu pedido de inscrição foi marcado como válido"
          expect(page).to have_content "1 mensagem não lida"
          click_link_and_wait "Clique aqui para editar"
          expect(page).to have_current_path("/enrollment/#{@enrollment3.id}/enroll/2022-2")
        end
      end

      describe "requested enrollment request" do
        before(:all) do
          @class_enrollment_request1.update!(status: ClassEnrollmentRequest::REQUESTED)
          @class_enrollment_request2.update!(status: ClassEnrollmentRequest::REQUESTED)
          @class_enrollment_request4.update!(status: ClassEnrollmentRequest::REQUESTED)
        end
        after(:all) do
          @class_enrollment_request1.update!(status: ClassEnrollmentRequest::VALID)
          @class_enrollment_request2.update!(status: ClassEnrollmentRequest::INVALID)
          @class_enrollment_request4.update!(status: ClassEnrollmentRequest::VALID)
        end

        before(:each) do
          visit student_enrollment_path(@enrollment3.id)
        end

        it "should show edit option" do
          expect(page).to have_content "Inscrições em disciplinas do semestre 2022.2 estão abertas!"
          expect(page).to have_content "1 mensagem não lida"
          click_link_and_wait "Clique aqui para editar seu pedido de inscrição."
          expect(page).to have_current_path("/enrollment/#{@enrollment3.id}/enroll/2022-2")
        end
      end

      describe "effected enrollment request" do
        before(:all) do
          @class_enrollment_request1.update!(enrollment_request: @enrollment_request4_2022_2)
          @class_enrollment_request2.update!(enrollment_request: @enrollment_request4_2022_2)
          @class_enrollment_request3.update!(enrollment_request: @enrollment_request4_2022_2)
          @class_enrollment_request4.update!(action: ClassEnrollmentRequest::INSERT, status: ClassEnrollmentRequest::EFFECTED)
        end
        after(:all) do
          @class_enrollment_request1.update!(enrollment_request: @enrollment_request3_2022_2)
          @class_enrollment_request2.update!(enrollment_request: @enrollment_request3_2022_2)
          @class_enrollment_request3.update!(enrollment_request: @enrollment_request3_2022_2)
          @class_enrollment_request4.update!(action: ClassEnrollmentRequest::REMOVE, status: ClassEnrollmentRequest::VALID)
        end

        before(:each) do
          visit student_enrollment_path(@enrollment3.id)
        end

        it "should show edit option" do
          expect(page).to have_content "Inscrições em disciplinas do semestre 2022.2 estão abertas!"
          expect(page).to have_content "Seu pedido de inscrição foi efetivado."
          expect(page).to have_content "1 mensagem não lida"
          click_link_and_wait "Clique aqui para se inscrever em outras disciplinas"
          expect(page).to have_current_path("/enrollment/#{@enrollment3.id}/enroll/2022-2")
        end
      end
    end

    describe "during adjust period" do
      before(:all) do
        @class_schedule.enrollment_start = 3.days.ago
        @class_schedule.enrollment_end = 2.days.ago
        @class_schedule.period_start = 1.days.ago
        @class_schedule.enrollment_insert = 3.days.from_now
        @class_schedule.enrollment_remove = 3.days.from_now
        @class_schedule.save!
      end
      after(:all) do
        @class_schedule.enrollment_start = DateTime.new(2022, 8, 8, 0, 0, 0, Time.zone.formatted_offset)
        @class_schedule.enrollment_end = DateTime.new(2022, 8, 11, 23, 59, 59, Time.zone.formatted_offset)
        @class_schedule.period_start = DateTime.new(2022, 8, 22, 0, 0, 0, Time.zone.formatted_offset)
        @class_schedule.enrollment_insert = DateTime.new(2022, 9, 6, 23, 59, 59, Time.zone.formatted_offset)
        @class_schedule.enrollment_remove = DateTime.new(2022, 9, 21, 23, 59, 59, Time.zone.formatted_offset)
        @enrollment_request3_2022_2.student_view_at = 3.days.ago
        @class_schedule.save!
      end

      before(:each) do
        login_as(@student_user)
        visit student_enrollment_path(@enrollment3.id)
      end

      it "should show edit option" do
        expect(page).to have_content "Período de ajustes do semestre 2022.2 está aberto!"
        expect(page).to have_content "Seu pedido de inscrição foi marcado como inválido"
        expect(page).to have_content "1 mensagem não lida"
        click_link_and_wait "Clique aqui para editar"
        expect(page).to have_current_path("/enrollment/#{@enrollment3.id}/enroll/2022-2")
      end
    end
  end

  describe "enroll" do
    before(:all) do
      @class_schedule.enrollment_start = 3.days.ago
      @class_schedule.enrollment_end = 3.days.from_now
      @class_schedule.period_start = 4.days.from_now
      @class_schedule.enrollment_insert = 5.days.from_now
      @class_schedule.enrollment_remove = 6.days.from_now
      @class_schedule.save!
    end
    after(:all) do
      @class_schedule.enrollment_start = DateTime.new(2022, 8, 8, 0, 0, 0, Time.zone.formatted_offset)
      @class_schedule.enrollment_end = DateTime.new(2022, 8, 11, 23, 59, 59, Time.zone.formatted_offset)
      @class_schedule.save!
    end

    describe "new enrollment" do
      before(:each) do
        login_as(@student_user)
        visit student_enroll_path(id: @enrollment2.id, year: 2022, semester: 2)
      end

      it "should show header" do
        expect(page).to have_content "Inscrição em disciplinas do semestre 2022.2"
        expect(page).to have_content "Datas"
        expect(page).to have_content "Início do Período de Inscrições"
        expect(page).to have_content "Fim do Período de Inscrições"
        expect(page).to have_content "Início do Período de Ajustes"
        expect(page).to have_content "Limite para Adicionar Disciplinas"
        expect(page).to have_content "Limite para Remover Disciplinas"
      end

      it "should show available classes" do
        expect(page.all(".enroll-table tr th").map(&:text)).to eq [
          "Inscrição", "Disciplina", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Professor"
        ]
        expect(page.all(".enroll-table tbody tr td.cell-disciplina").map(&:text)).to eq [
          "Algebra", "Pesquisa", "Programação", "Tópicos em ES (Mineração de Repositórios)", "Versionamento"
        ]
      end

      it "should show the proper allocations" do
        # Two allocations in the same day
        expect(page.all(".enroll-table tbody tr:nth-of-type(1) td.cell-segunda").map(&:text)).to have_text "11-13"
        expect(page.all(".enroll-table tbody tr:nth-of-type(1) td.cell-segunda").map(&:text)).to have_text "14-16"
        # No allocations for class
        expect(page.all(".enroll-table tbody tr:nth-of-type(2) td.cell-segunda").map(&:text)).to eq [
          "*"
        ]
        # Simple allocation
        expect(page.all(".enroll-table tbody tr:nth-of-type(5) td.cell-segunda").map(&:text)).to eq [
          "11-13"
        ]
      end

      it "should show list of professors in on demand class" do
        expect(page.all("select#enrollment_request-course_ids-#{@course6.id}-professor option").map(&:text)).to eq [
          "Selecione", "Erica", "Fiona", "Gi"
        ]
      end

      it "should show messages" do
        expect(page).to have_content "Mensagens"
        expect(page).to have_content "Enviar mensagem (não será possível editar depois)"
      end
    end

    describe "existing enrollment" do
      before(:each) do
        login_as(@student_user)
        visit student_enroll_path(id: @enrollment3.id, year: 2022, semester: 2)
      end

      it "should show invalid notice" do
        expect(page).to have_content "Sua inscrição está inválida"
      end

      it "should not show classes that the enrollment has a previous approval" do
        expect(page.all(".enroll-table tbody tr td.cell-disciplina").map(&:text)).to eq [
          "Pesquisa", "Programação", "Tópicos em ES (Mineração de Repositórios)", "Versionamento"
        ]
      end

      it "should not show a list of professors in an on demand class if it was selected before" do
        expect(page).not_to have_css("select#enrollment_request-course_ids-#{@course6.id}-professor")
      end

      it "should show existing messages" do
        expect(page).to have_content "Some comment"
      end
    end

    describe "on_demand default" do
      before(:each) do
        login_as(@student_user)
      end

      describe "enrollment without advisor" do
        it "should select advisor by default" do
          visit student_enroll_path(id: @enrollment2.id, year: 2022, semester: 2)
          expect(find_field("enrollment_request-course_ids-#{@course6.id}-professor").value).to eq ""
        end
      end

      describe "enrollment with advisor" do
        before(:all) do
          @advisement = FactoryBot.create(:advisement, enrollment: @enrollment2, professor: @professor1, main_advisor: true)
        end
        after(:all) do
          @advisement.destroy
        end

        it "should select advisor by default" do
          visit student_enroll_path(id: @enrollment2.id, year: 2022, semester: 2)
          expect(find_field("enrollment_request-course_ids-#{@course6.id}-professor").value).to eq @professor1.id.to_s
        end
      end
    end
  end

  describe "save_enroll" do
    before(:all) do
      @class_schedule.enrollment_start = 3.days.ago
      @class_schedule.enrollment_end = 3.days.from_now
      @class_schedule.period_start = 4.days.from_now
      @class_schedule.enrollment_insert = 5.days.from_now
      @class_schedule.enrollment_remove = 6.days.from_now
      @class_schedule.save!
    end
    after(:all) do
      @class_schedule.enrollment_start = DateTime.new(2022, 8, 8, 0, 0, 0, Time.zone.formatted_offset)
      @class_schedule.enrollment_end = DateTime.new(2022, 8, 11, 23, 59, 59, Time.zone.formatted_offset)
      @class_schedule.save!
    end

    before(:each) do
      login_as(@student_user)
    end

    describe "new enrollment_request" do
      it "should create a new enrollment request for users without it" do
        visit student_enroll_path(id: @enrollment2.id, year: 2022, semester: 2)
        find("#table_row_2").click
        click_button_and_wait "Enviar"
        expect(page).to have_current_path("/enrollment/#{@enrollment2.id}")

        last_request = EnrollmentRequest.last
        expect(last_request.id).not_to eq @enrollment_request4_2022_2.id
        expect(last_request.enrollment.id).to eq @enrollment2.id
        expect(last_request.year).to eq 2022
        expect(last_request.semester).to eq 2

        last_class_request = ClassEnrollmentRequest.last
        expect(last_class_request.id).not_to eq @class_enrollment_request4.id
        expect(last_class_request.enrollment_request.id).to eq last_request.id
        expect(last_class_request.course_class.id).to eq @course_class8.id
        expect(last_class_request.action).to eq ClassEnrollmentRequest::INSERT
        expect(last_class_request.status).to eq ClassEnrollmentRequest::REQUESTED
        last_request.destroy!
      end

      it "should send a message" do
        visit student_enroll_path(id: @enrollment2.id, year: 2022, semester: 2)
        find("#table_row_2").click
        fill_in "enrollment_request_message", with: "Mensagem de teste"
        click_button_and_wait "Enviar"
        expect(page).to have_current_path("/enrollment/#{@enrollment2.id}")

        last_request = EnrollmentRequest.last
        last_comment = EnrollmentRequestComment.last
        expect(last_comment.id).not_to eq @enrollment_request_comment.id
        expect(last_comment.enrollment_request.id).to eq last_request.id
        expect(last_comment.user.id).to eq @student_user.id
        expect(last_comment.message).to eq "Mensagem de teste"
        last_request.destroy!
      end

      it "should not create an on demand course_class when the class already exists" do
        visit student_enroll_path(id: @enrollment2.id, year: 2022, semester: 2)
        find("select#enrollment_request-course_ids-#{@course6.id}-professor").find(:option, text: "Gi").select_option
        find("#table_row_demand_1").click
        click_button_and_wait "Enviar"
        expect(page).to have_current_path("/enrollment/#{@enrollment2.id}")

        last_request = EnrollmentRequest.last
        last_class_request = ClassEnrollmentRequest.last
        expect(last_class_request.course_class.id).to eq @course_class7.id
        expect(last_class_request.action).to eq ClassEnrollmentRequest::INSERT
        expect(last_class_request.status).to eq ClassEnrollmentRequest::REQUESTED
        last_request.destroy!
      end

      it "should create an on demand course_class when the class does not exist" do
        visit student_enroll_path(id: @enrollment2.id, year: 2022, semester: 2)
        find("select#enrollment_request-course_ids-#{@course6.id}-professor").find(:option, text: "Erica").select_option
        find("#table_row_demand_1").click
        click_button_and_wait "Enviar"
        expect(page).to have_current_path("/enrollment/#{@enrollment2.id}")

        last_course_class = CourseClass.last
        expect(last_course_class.name).to eq "Pesquisa"
        expect(last_course_class.course.id).to eq @course6.id
        expect(last_course_class.professor.id).to eq @professor1.id
        expect(last_course_class.year).to eq 2022
        expect(last_course_class.semester).to eq 2

        last_request = EnrollmentRequest.last
        last_class_request = ClassEnrollmentRequest.last
        expect(last_class_request.course_class.id).not_to eq @course_class7.id
        expect(last_class_request.course_class.id).not_to eq @course_class8.id
        expect(last_class_request.course_class.id).to eq last_course_class.id
        expect(last_class_request.action).to eq ClassEnrollmentRequest::INSERT
        expect(last_class_request.status).to eq ClassEnrollmentRequest::REQUESTED
        last_request.destroy!
        last_course_class.destroy!
      end
    end

    describe "edit existing enrollment_request" do
      it "should create a new class enrollment request during edit" do
        visit student_enroll_path(id: @enrollment4.id, year: 2022, semester: 2)
        find("#table_row_2").click
        click_button_and_wait "Enviar"
        expect(page).to have_current_path("/enrollment/#{@enrollment4.id}")

        last_class_request = ClassEnrollmentRequest.last
        expect(last_class_request.id).not_to eq @class_enrollment_request_4_0.id
        expect(last_class_request.enrollment_request.id).to eq @enrollment_request4_2022_2.id
        expect(last_class_request.course_class.id).to eq @course_class8.id
        expect(last_class_request.action).to eq ClassEnrollmentRequest::INSERT
        expect(last_class_request.status).to eq ClassEnrollmentRequest::REQUESTED
        last_class_request.destroy!
      end
    end

    describe "remove enrollment_request" do
      it "should be possible to remove enrollment request by checking the destroy option" do
        visit student_enroll_path(id: @enrollment4.id, year: 2022, semester: 2)
        find("#table_row_4").click
        click_button_and_wait "Enviar"
        find("#delete_request").set(true)
        click_button_and_wait "Enviar"
        expect(page).to have_current_path("/enrollment/#{@enrollment4.id}")
        expect(page).to have_content "Inscrições em disciplinas do semestre 2022.2 estão abertas!"
        expect(page).to have_content "Clique aqui para fazer um pedido de inscrição."

        expect { @class_enrollment_request_4_0.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { @enrollment_request4_2022_2.reload }.to raise_error(ActiveRecord::RecordNotFound)

        @destroy_all << @enrollment_request4_2022_2 = FactoryBot.create(:enrollment_request, enrollment: @enrollment4, year: 2022, semester: 2, student_view_at: 3.days.ago)
        @destroy_all << @class_enrollment_request_4_0 = FactoryBot.create(:class_enrollment_request, enrollment_request: @enrollment_request4_2022_2, course_class: @course_class4, action: ClassEnrollmentRequest::INSERT, status: ClassEnrollmentRequest::REQUESTED)
      end
    end

    describe "validations" do
      it "should prevent the submission without a selection" do
        visit student_enroll_path(id: @enrollment2.id, year: 2022, semester: 2)
        click_button_and_wait "Enviar"
        expect(page).to have_content "1 erro impediu que pedido de inscrição fosse salvo"
        expect(page).to have_content "Disciplinas deve incluir pelo menos uma seleção"
      end

      it "should prevent the removal of all classes during edit" do
        visit student_enroll_path(id: @enrollment4.id, year: 2022, semester: 2)
        find("#table_row_4").click
        click_button_and_wait "Enviar"
        expect(page).to have_content "1 erro impediu que pedido de inscrição fosse salvo"
        expect(page).to have_content "Disciplinas deve incluir pelo menos uma seleção"
        expect(page).to have_content "Remover pedido?"
      end

      it "should prevent the submission with time conflicts" do
        visit student_enroll_path(id: @enrollment2.id, year: 2022, semester: 2)
        find("#table_row_0").click
        find("#table_row_4").click
        click_button_and_wait "Enviar"
        expect(page).to have_content "1 erro impediu que pedido de inscrição fosse salvo"
        expect(page).to have_content "Há pelo menos um conflito de horário nas disciplinas escolhidas. Confira Segunda, 11-13"
      end

      it "should require the selection of a professor for on demand classes" do
        visit student_enroll_path(id: @enrollment2.id, year: 2022, semester: 2)
        find("#table_row_demand_1").click
        click_button_and_wait "Enviar"
        expect(page).to have_content "É necessário selecionar um professor para Pesquisa"
      end
    end
  end
end
