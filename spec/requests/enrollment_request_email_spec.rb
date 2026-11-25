# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O formulário do pedido de inscrição prepara o e-mail ao aluno antes de
# gravar (EnrollmentRequestsController#before_update_save). A gravação ainda
# pode ser recusada pela validação de cada disciplina: o e-mail não pode
# anunciar o que não foi gravado. A entrega é conferida no
# ActionMailer::Base.deliveries, sem stub do Notifier.
RSpec.describe "Pedido de inscrição: e-mail ao aluno", type: :request do
  before(:each) do
    student = FactoryBot.create(:student, email: "aluno.pedido@example.com")
    @enrollment = FactoryBot.create(
      :enrollment, student: student, admission_date: Date.new(2019, 3, 1),
      enrollment_status: FactoryBot.create(:enrollment_status, user: true)
    )
    @course_class = FactoryBot.create(:course_class, year: 2020, semester: 1)
    @pedido = FactoryBot.create(:enrollment_request, enrollment: @enrollment, year: 2020, semester: 1)
    @cer = FactoryBot.create(
      :class_enrollment_request, enrollment_request: @pedido, course_class: @course_class,
      status: ClassEnrollmentRequest::REQUESTED
    )
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm.email.pedido@ic.uff.br", "Adm")
    # A confirmação do usuário criado acima não é deste assunto.
    ActionMailer::Base.deliveries.clear
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  def grava(status)
    put enrollment_request_path(@pedido), params: { record: {
      comment_message: "",
      class_enrollment_requests: {
        "0" => "",
        @cer.id.to_s => {
          id: @cer.id.to_s, course_class: @course_class.id.to_s,
          class_enrollment: "", status: status
        }
      }
    } }
  end

  def destinatarios
    ActionMailer::Base.deliveries.flat_map(&:to)
  end

  it "controle: a gravação aceita avisa o aluno" do
    grava(ClassEnrollmentRequest::VALID)

    expect(@cer.reload.status).to eq(ClassEnrollmentRequest::VALID)
    expect(destinatarios).to eq(["aluno.pedido@example.com"])
  end

  # O trancamento criado depois de o formulário abrir invalida o pedido; pôr
  # a disciplina em Válida esbarra na validação do trancamento.
  it "a gravação recusada não avisa o aluno" do
    FactoryBot.create(:enrollment_hold, enrollment: @enrollment, year: 2020, semester: 1)
    expect(@cer.reload.status).to eq(ClassEnrollmentRequest::INVALID)

    grava(ClassEnrollmentRequest::VALID)

    expect(@cer.reload.status).to eq(ClassEnrollmentRequest::INVALID)
    expect(destinatarios).to eq([])
  end
end
