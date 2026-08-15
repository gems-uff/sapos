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
end
