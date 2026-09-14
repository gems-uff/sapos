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
end
