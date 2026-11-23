# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Trancamento da matrícula no semestre e os pedidos de inscrição em disciplina.
# O efeito que se quer ao trancar é que o aluno não fique inscrito em nada
# naquele semestre: o trancamento só é aceito sem inscrição no período
# (EnrollmentHold#verify_class_enrollments), invalida os pedidos pendentes, e
# nada que ocupe o período passa depois dele -- nem efetivação pela
# secretaria, nem pedido novo do aluno. A remoção já efetivada continua
# Efetivada: o aluno saiu da turma, e é isso que ela diz.
#
# A entrega do e-mail é conferida no ActionMailer::Base.deliveries, sem stub do
# Notifier.
RSpec.describe "Trancamento e pedidos de inscrição", type: :request do
  requested = ClassEnrollmentRequest::REQUESTED
  valid = ClassEnrollmentRequest::VALID
  invalid = ClassEnrollmentRequest::INVALID
  effected = ClassEnrollmentRequest::EFFECTED

  before(:each) do
    student = FactoryBot.create(:student, email: "aluno.trancado@example.com")
    @enrollment = FactoryBot.create(
      :enrollment, student: student, level: FactoryBot.create(:level),
      admission_date: Date.new(2024, 3, 1),
      enrollment_status: FactoryBot.create(:enrollment_status, user: true)
    )
    @student_user = create_confirmed_user(
      [FactoryBot.create(:role_aluno)], "aluno.trancado@ic.uff.br", "Aluno",
      "A1b2c3d4!", student: student
    )
    @admin = create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm.trancado@ic.uff.br", "Adm"
    )
    FactoryBot.create(
      :class_schedule, year: 2026, semester: 2,
      enrollment_start: 3.days.ago, enrollment_end: 3.days.from_now,
      period_start: 10.days.from_now,
      enrollment_insert: 3.days.from_now, enrollment_remove: 3.days.from_now
    )
    type = FactoryBot.create(:course_type, on_demand: false, allow_multiple_classes: false)
    professor = FactoryBot.create(:professor, email: "professor.trancado@example.com")
    @a = FactoryBot.create(
      :course_class, course: FactoryBot.create(:course, name: "Alfa", course_type: type),
      professor: professor, year: 2026, semester: 2
    )
    @b = FactoryBot.create(
      :course_class, course: FactoryBot.create(:course, name: "Beta", course_type: type),
      professor: professor, year: 2026, semester: 2
    )
    @pedido = FactoryBot.create(:enrollment_request, enrollment: @enrollment, year: 2026, semester: 2)
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  def tranca
    EnrollmentHold.create!(enrollment: @enrollment, year: 2026, semester: 2, number_of_semesters: 1)
    ActionMailer::Base.deliveries.clear
  end

  def adicao(status)
    FactoryBot.create(
      :class_enrollment_request, enrollment_request: @pedido, course_class: @a,
      action: ClassEnrollmentRequest::INSERT, status: status
    )
  end

  def grava(cer, status, comentario: "")
    put enrollment_request_path(@pedido), params: { record: {
      comment_message: comentario,
      class_enrollment_requests: {
        "0" => "",
        cer.id.to_s => {
          id: cer.id.to_s, course_class: cer.course_class_id.to_s,
          class_enrollment: cer.reload.class_enrollment_id.to_s, status: status
        }
      }
    } }
  end

  def erros_visiveis
    Nokogiri::HTML(response.body)
      .css(".errorExplanation li, .association-record-errors li, #error_explanation li")
      .map { |li| li.text.squish }
  end

  def inscricoes
    ClassEnrollment.where(enrollment: @enrollment).count
  end

  def destinatarios
    ActionMailer::Base.deliveries.flat_map(&:to)
  end

  def trancada
    ClassEnrollmentRequest.new.errors.full_message(
      :enrollment,
      I18n.t(
        "activerecord.errors.models.class_enrollment_request.attributes." \
        "enrollment.enrollment_is_held"
      )
    )
  end

  it "invalida a adição pendente ao trancar" do
    cer = adicao(requested)

    tranca

    expect(cer.reload.status).to eq(invalid)
  end

  describe "remoção efetivada antes do trancamento" do
    before(:each) do
      inscricao = ClassEnrollment.create!(
        enrollment: @enrollment, course_class: @a, situation: ClassEnrollment::REGISTERED
      )
      @remocao = FactoryBot.create(
        :class_enrollment_request, enrollment_request: @pedido, course_class: @a,
        class_enrollment: inscricao, action: ClassEnrollmentRequest::REMOVE, status: requested
      )
      expect(@remocao.set_status!(effected)).to be(true)
      tranca
      sign_in @admin
    end

    it "continua Efetivada, sem inscrição" do
      expect(@remocao.reload.status).to eq(effected)
      expect(inscricoes).to eq(0)
    end

    it "não impede gravar o pedido pelo formulário" do
      grava(@remocao, effected, comentario: "Trancamento registrado")

      expect(response).to have_http_status(:redirect)
      expect(@pedido.enrollment_request_comments.count).to eq(1)
      expect(destinatarios).to eq(["aluno.trancado@example.com"])
    end

    it "não volta atrás, porque a inscrição não pode voltar" do
      put set_requested_class_enrollment_request_path(@remocao)

      expect(@remocao.reload.status).to eq(effected)
      expect(inscricoes).to eq(0)
      errors = ClassEnrollment.new.errors
      expect(flash[:error]).to include(
        errors.full_message(:enrollment, errors.generate_message(:enrollment, :enrollment_is_held))
      )
      expect(destinatarios).to eq([])
    end
  end

  describe "secretaria efetivando com o aluno trancado" do
    before(:each) do
      @cer = adicao(requested)
      tranca
      sign_in @admin
    end

    it "pelo ícone, recusa e diz por quê" do
      put set_effected_class_enrollment_request_path(@cer)

      expect(flash[:error]).to eq([trancada])
      expect([@cer.reload.status, inscricoes, destinatarios]).to eq([invalid, 0, []])
    end

    it "pelo formulário, recusa e diz por quê" do
      grava(@cer, effected)

      expect(erros_visiveis).to include(trancada)
      expect([@cer.reload.status, inscricoes, destinatarios]).to eq([invalid, 0, []])
    end

    it "pelo lote, recusa e diz por quê" do
      get class_enrollment_requests_path
      post effect_class_enrollment_requests_path

      expect(Array(flash[:error]).join).to include(trancada)
      expect([@cer.reload.status, inscricoes, destinatarios]).to eq([invalid, 0, []])
    end

    it "também não deixa validar" do
      put set_valid_class_enrollment_request_path(@cer)

      expect(flash[:error]).to eq([trancada])
      expect(@cer.reload.status).not_to eq(valid)
    end
  end

  describe "aluno pedindo disciplina depois do trancamento" do
    def pede(*turmas)
      sign_in @student_user
      post "/enrollment/#{@enrollment.id}/enroll/2026-2", params: { enrollment_request: {
        course_class_ids: [""] + turmas.map { |turma| turma.id.to_s }, message: ""
      } }
    end

    def turmas_pedidas
      ClassEnrollmentRequest.joins(:enrollment_request)
        .where(enrollment_requests: { enrollment_id: @enrollment.id })
        .map(&:course_class)
    end

    it "com pedido no semestre, recusa e diz por quê" do
      adicao(requested)
      tranca

      pede(@a, @b)

      expect(response).to have_http_status(:ok)
      expect(erros_visiveis).to include(trancada)
      expect(turmas_pedidas).to eq([@a])
      expect(destinatarios).to eq([])
    end

    it "sem pedido no semestre, recusa e não grava pedido", pending: "issue #784" do
      @pedido.destroy!
      tranca

      pede(@b)

      expect(response).to have_http_status(:ok)
      expect(turmas_pedidas).to eq([])
      expect(EnrollmentRequest.where(enrollment: @enrollment)).to be_empty
      expect(erros_visiveis).to include(trancada)
    end

    it "controle: sem trancamento, sem pedido no semestre, grava o pedido" do
      @pedido.destroy!

      pede(@b)

      expect(response).to have_http_status(:redirect)
      expect(turmas_pedidas).to eq([@b])
    end
  end
end
