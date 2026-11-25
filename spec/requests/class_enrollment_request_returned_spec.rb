# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A remoção efetivada apagou a inscrição, e a secretaria a recriou pela tela de
# inscrições, por fora do pedido. O aluno está na turma, mas a remoção diz
# Efetivada: desfazê-la tem de ser possível, e religa a remoção à inscrição
# que voltou, em vez de criar outra (a segunda seria recusada pela unicidade
# da turma). A entrega do e-mail é conferida no ActionMailer::Base.deliveries,
# sem stub do Notifier.
RSpec.describe "Remoção efetivada cuja inscrição voltou pela tela", type: :request do
  requested = ClassEnrollmentRequest::REQUESTED
  invalid = ClassEnrollmentRequest::INVALID
  effected = ClassEnrollmentRequest::EFFECTED

  before(:each) do
    student = FactoryBot.create(:student, email: "aluno.volta@example.com")
    @enrollment = FactoryBot.create(
      :enrollment, student: student, level: FactoryBot.create(:level),
      enrollment_status: FactoryBot.create(:enrollment_status, user: true)
    )
    FactoryBot.create(
      :class_schedule, year: 2026, semester: 2,
      enrollment_start: 30.days.ago, enrollment_end: 20.days.ago,
      period_start: 10.days.ago, enrollment_insert: 3.days.from_now,
      enrollment_remove: 3.days.from_now
    )
    type = FactoryBot.create(:course_type, on_demand: false, allow_multiple_classes: false)
    @a = FactoryBot.create(
      :course_class, course: FactoryBot.create(:course, course_type: type),
      professor: FactoryBot.create(:professor, email: "professor.volta@example.com"),
      year: 2026, semester: 2
    )
    @pedido = FactoryBot.create(:enrollment_request, enrollment: @enrollment, year: 2026, semester: 2)
    inscricao = ClassEnrollment.create!(
      enrollment: @enrollment, course_class: @a, situation: ClassEnrollment::REGISTERED
    )
    @remocao = FactoryBot.create(
      :class_enrollment_request, enrollment_request: @pedido, course_class: @a,
      class_enrollment: inscricao, action: ClassEnrollmentRequest::REMOVE, status: requested
    )
    expect(@remocao.set_status!(effected)).to be(true)
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm.volta@ic.uff.br", "Adm")
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  def recria_pela_tela
    post class_enrollments_path, params: { record: {
      enrollment: @enrollment.id.to_s, course_class: @a.id.to_s,
      situation: ClassEnrollment::REGISTERED
    } }
    @recriada = ClassEnrollment.find_by!(enrollment: @enrollment, course_class: @a)
    ActionMailer::Base.deliveries.clear
  end

  def inscricoes
    ClassEnrollment.where(enrollment: @enrollment, course_class: @a)
  end

  def destinatarios
    ActionMailer::Base.deliveries.flat_map(&:to)
  end

  it "controle: sem a inscrição recriada, desfazer recria a inscrição" do
    ActionMailer::Base.deliveries.clear

    put set_requested_class_enrollment_request_path(@remocao)

    expect(@remocao.reload.status).to eq(requested)
    expect(@remocao.class_enrollment).to eq(inscricoes.sole)
    expect(destinatarios).to eq(["professor.volta@example.com"])
  end

  describe "com a inscrição recriada pela tela" do
    before(:each) { recria_pela_tela }

    [[requested, :set_requested_class_enrollment_request_path],
     [invalid, :set_invalid_class_enrollment_request_path]].each do |status, path|
      it "pelo ícone, volta a #{status} ligada à inscrição que voltou" do
        put send(path, @remocao)

        expect(flash[:error]).to be_blank
        expect(@remocao.reload.status).to eq(status)
        expect(@remocao.class_enrollment).to eq(@recriada)
        expect(inscricoes.to_a).to eq([@recriada])
        expect(destinatarios).to eq([])
      end
    end

    it "pelo formulário, volta a Solicitada ligada à inscrição que voltou" do
      put enrollment_request_path(@pedido), params: { record: {
        comment_message: "",
        class_enrollment_requests: { "0" => "", @remocao.id.to_s => {
          id: @remocao.id.to_s, course_class: @a.id.to_s,
          class_enrollment: "", status: requested
        } }
      } }

      expect(response).to have_http_status(:redirect)
      expect(@remocao.reload.status).to eq(requested)
      expect(@remocao.class_enrollment).to eq(@recriada)
      expect(inscricoes.to_a).to eq([@recriada])
      expect(destinatarios).to eq(["aluno.volta@example.com"])
    end

    it "efetivada de novo, apaga a inscrição que voltou" do
      put set_requested_class_enrollment_request_path(@remocao)

      put set_effected_class_enrollment_request_path(@remocao)

      expect(@remocao.reload.status).to eq(effected)
      expect(inscricoes).to be_empty
    end
  end
end
