# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Recusas da tela de inscricao do aluno que nenhum exemplo percorria (#720):
# matricula desligada, gravacao fora da janela de inscricao, pedido de apagar
# que destroy_request recusa e gravacao invalida com comentario ja montado.
RSpec.describe "Inscricao do aluno: recusas", type: :request do
  before(:each) do
    @level = FactoryBot.create(:level)
    @student = FactoryBot.create(:student, email: "aluna.recusas@ic.uff.br")
    @enrollment = FactoryBot.create(
      :enrollment, student: @student, level: @level,
      enrollment_status: FactoryBot.create(:enrollment_status, user: true)
    )
    professor = FactoryBot.create(:professor)
    FactoryBot.create(:advisement_authorization, professor:, level: @level)
    FactoryBot.create(:advisement, professor:, enrollment: @enrollment, main_advisor: true)
    @course_class = FactoryBot.create(:course_class, year: 2020, semester: 1)
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_aluno)], "aluna.recusas@ic.uff.br", "Aluna", "A1b2c3d4!", student: @student
    )
    allow(Notifier).to receive(:send_emails)
  end

  after(:each) { travel_back }

  def janela(insercao_ate:, remocao_ate:)
    FactoryBot.create(
      :class_schedule, year: 2020, semester: 1,
      enrollment_start: Time.utc(2020, 3, 1), enrollment_end: Time.utc(2020, 3, 31),
      period_start: Time.utc(2020, 3, 1), period_end: Time.utc(2020, 7, 31),
      enrollment_insert: insercao_ate, enrollment_remove: remocao_ate,
      grades_deadline: Time.utc(2020, 8, 31)
    )
  end

  def pedido_efetivado
    pedido = FactoryBot.create(:enrollment_request, enrollment: @enrollment, year: 2020, semester: 1)
    FactoryBot.create(
      :class_enrollment_request, enrollment_request: pedido, course_class: @course_class,
      status: ClassEnrollmentRequest::EFFECTED
    )
    pedido.reload
  end

  def gravar(params)
    post save_student_enroll_path(id: @enrollment.id, year: 2020, semester: 1),
      params: { enrollment_request: params }
  end

  it "manda a matricula desligada de volta para a ficha" do
    FactoryBot.create(:dismissal, enrollment: @enrollment)

    get "/enrollment/#{@enrollment.id}/enroll/2020-1"

    expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
    expect(flash[:alert]).to eq(
      I18n.t("student_enrollment.alert.dismissed_enrollment", enrollment: @enrollment.id.to_s)
    )
  end

  # O GET abre a tela fora da janela; so a gravacao confere o horario.
  it "abre a tela fora da janela, mas recusa gravar" do
    janela(insercao_ate: Time.utc(2020, 4, 15), remocao_ate: Time.utc(2020, 4, 15))
    travel_to Time.utc(2020, 9, 1, 12, 0, 0)

    get "/enrollment/#{@enrollment.id}/enroll/2020-1"
    expect(response).to have_http_status(:ok)

    expect do
      gravar(course_class_ids: [@course_class.id.to_s], message: "")
    end.not_to change { EnrollmentRequest.count }

    expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
    expect(flash[:alert]).to eq(
      I18n.t("student_enrollment.alert.closed_enrollment", year: "2020", semester: "1")
    )
  end

  context "so com a janela de insercao aberta" do
    before(:each) do
      @pedido = pedido_efetivado
      janela(insercao_ate: Time.utc(2020, 4, 30), remocao_ate: Time.utc(2020, 4, 15))
      travel_to Time.utc(2020, 4, 20, 12, 0, 0)
    end

    it "recusa apagar o pedido com disciplina efetivada e volta a tela com o erro" do
      gravar(delete_request: "1")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("fora do período de ajustes")
      cer = @pedido.reload.class_enrollment_requests.first
      expect(cer.action).to eq(ClassEnrollmentRequest::INSERT)
      expect(cer.status).to eq(ClassEnrollmentRequest::EFFECTED)
      expect(Notifier).not_to have_received(:send_emails)
    end
  end

  context "na janela principal" do
    before(:each) do
      janela(insercao_ate: Time.utc(2020, 3, 31), remocao_ate: Time.utc(2020, 3, 31))
      travel_to Time.utc(2020, 3, 15, 12, 0, 0)
    end

    # Com mensagem, o comentario e montado antes do save_request; se a
    # gravacao falha, ele sai do pedido e nao e gravado.
    it "recusa o pedido vazio com mensagem sem gravar o comentario" do
      expect do
        gravar(course_class_ids: [], message: "Mensagem que nao fica")
      end.not_to change { EnrollmentRequestComment.count }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("deve incluir pelo menos uma seleção")
      expect(EnrollmentRequest.where(enrollment: @enrollment)).to be_empty
      expect(Notifier).not_to have_received(:send_emails)
    end
  end
end
