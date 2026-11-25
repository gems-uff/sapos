# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "StudentEnrollmentController", type: :request do
  before(:each) do
    @role_student = FactoryBot.create(:role_aluno)
    @level = FactoryBot.create(:level, name: "Mestrado")
    @enrollment_status = FactoryBot.create(
      :enrollment_status, name: "Regular", user: true
    )
    @student = FactoryBot.create(:student, name: "Ana")
    @enrollment = FactoryBot.create(
      :enrollment, enrollment_number: "M01", student: @student,
      level: @level, enrollment_status: @enrollment_status
    )
    @user = create_confirmed_user(
      [@role_student], "ana.sapos@ic.uff.br", "Ana", "A1b2c3d4!",
      student: @student
    )
    sign_in @user
  end

  describe "GET enroll for a semester without a class schedule" do
    # Aluno abrindo o semestre antes de o calendário ser cadastrado percorre um
    # caminho legítimo. Ele não pode ser acusado de tentativa de invasão.
    it "redirects to the enrollment with an informative message" do
      get "/enrollment/#{@enrollment.id}/enroll/2026-2"

      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(flash[:alert]).to eq I18n.t(
        "student_enrollment.alert.unavailable_semester", year: "2026", semester: "2"
      )
    end
  end

  describe "GET enroll for an enrollment of another student" do
    it "is still denied" do
      other_student = FactoryBot.create(:student, name: "Bruno")
      other_enrollment = FactoryBot.create(
        :enrollment, enrollment_number: "M02", student: other_student,
        level: @level, enrollment_status: @enrollment_status
      )

      get "/enrollment/#{other_enrollment.id}/enroll/2026-2"

      # CanCan::AccessDenied não tem mapeamento em rescue_responses, então
      # aparece como 500 — é a página que o SAPOS mostra a quem é barrado.
      expect(response).to have_http_status(:internal_server_error)
      expect(response).not_to redirect_to(
        student_enrollment_path(other_enrollment.id)
      )
    end
  end

  describe "GET enroll advisor list only offers currently accredited professors" do
    # A lista de orientadores da tela de matrícula precisa casar com a validação:
    # oferecer só quem está credenciado na data de hoje (start_date já iniciado e
    # sem descredenciamento), e não apenas quem tem end_date nulo. O seletor só
    # aparece numa linha de curso on-demand, com a janela de inscrição aberta.
    before(:each) do
      FactoryBot.create(
        :class_schedule, year: 2026, semester: 2,
        enrollment_start: 3.days.ago, enrollment_end: 3.days.from_now
      )
      on_demand_type = FactoryBot.create(:course_type, on_demand: true)
      FactoryBot.create(:course, course_type: on_demand_type)

      current = FactoryBot.create(:professor, name: "OrientadorVigente")
      FactoryBot.create(:advisement_authorization, professor: current, level: @level,
                        start_date: Date.current - 1.day, end_date: nil)
      closed = FactoryBot.create(:professor, name: "OrientadorEncerrado")
      FactoryBot.create(:advisement_authorization, professor: closed, level: @level,
                        start_date: Date.current - 2.days, end_date: Date.current - 1.day)
      future = FactoryBot.create(:professor, name: "OrientadorFuturo")
      FactoryBot.create(:advisement_authorization, professor: future, level: @level,
                        start_date: Date.current + 1.day, end_date: nil)
    end

    it "shows the accredited advisor and hides the de-accredited and not-yet-started ones" do
      get "/enrollment/#{@enrollment.id}/enroll/2026-2"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("OrientadorVigente")
      expect(response.body).not_to include("OrientadorEncerrado")
      expect(response.body).not_to include("OrientadorFuturo")
    end
  end

  describe "GET enroll professor selector of an on-demand course" do
    # O seletor da disciplina sob demanda junta o professor de cada turma do
    # semestre com os orientadores credenciados. Cada professor tem de aparecer
    # uma vez, ainda que tenha duas turmas da disciplina.
    before(:each) do
      FactoryBot.create(
        :class_schedule, year: 2026, semester: 2,
        enrollment_start: 3.days.ago, enrollment_end: 3.days.from_now
      )
      on_demand_type = FactoryBot.create(:course_type, on_demand: true)
      @course = FactoryBot.create(:course, course_type: on_demand_type)
      @professor = FactoryBot.create(:professor, name: "ProfessorDaTurma")
    end

    def create_class(professor, name)
      FactoryBot.create(
        :course_class, course: @course, professor: professor,
        year: 2026, semester: 2, name: name
      )
    end

    def options_for(professor)
      get "/enrollment/#{@enrollment.id}/enroll/2026-2"
      expect(response).to have_http_status(:ok)
      select = Nokogiri::HTML(response.body).at_css(
        "select#enrollment_request-course_ids-#{@course.id}-professor"
      )
      expect(select).not_to be_nil
      select.css("option[value='#{professor.id}']").size
    end

    it "lists the professor of a single class once" do
      create_class(@professor, "A")

      expect(options_for(@professor)).to eq(1)
    end

    it "lists each professor once when the classes belong to different professors" do
      other = FactoryBot.create(:professor, name: "OutroProfessorDaTurma")
      create_class(@professor, "A")
      create_class(other, "B")

      expect(options_for(@professor)).to eq(1)
      expect(options_for(other)).to eq(1)
    end

    # O credenciado sai da lista das turmas e entra pela dos orientadores, que
    # vem sem repetição: por isso o defeito só alcança quem não é credenciado.
    it "lists an accredited advisor with two classes once" do
      FactoryBot.create(
        :advisement_authorization, professor: @professor, level: @level,
        start_date: Date.current - 1.day, end_date: nil
      )
      create_class(@professor, "A")
      create_class(@professor, "B")

      expect(options_for(@professor)).to eq(1)
    end

    it "lists a non-accredited professor with two classes once",
       pending: "issue #780" do
      create_class(@professor, "A")
      create_class(@professor, "B")

      expect(options_for(@professor)).to eq(1)
    end
  end
end
