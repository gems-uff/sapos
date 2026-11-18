# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O orientador pode editar a solicitacao de inscricao do orientando, mas nao
# efetivar disciplina (Ability: update sim, effect nao). Quem barra a efetivacao
# pelo formulario de edicao e o before_update_save do controller, com o erro
# cannot_effect -- linha que nenhum exemplo percorria (#720).
RSpec.describe "Orientador tentando efetivar pela edicao da solicitacao", type: :request do
  before(:each) do
    level = FactoryBot.create(:level)
    @enrollment = FactoryBot.create(:enrollment, level:)
    professor = FactoryBot.create(:professor)
    FactoryBot.create(:advisement_authorization, professor:, level:)
    FactoryBot.create(:advisement, professor:, enrollment: @enrollment, main_advisor: true)
    @pedido = FactoryBot.create(:enrollment_request, enrollment: @enrollment, year: 2020, semester: 1)
    @cer = FactoryBot.create(
      :class_enrollment_request, enrollment_request: @pedido,
      course_class: FactoryBot.create(:course_class, year: 2020, semester: 1),
      status: ClassEnrollmentRequest::VALID
    )
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_professor)], "orientador.efetivar@ic.uff.br", "Orientador", professor:
    )
    allow(Notifier).to receive(:send_emails)
  end

  def marcar(status)
    patch enrollment_request_path(@pedido), params: {
      record: {
        comment_message: "",
        class_enrollment_requests: { @cer.id.to_s => { id: @cer.id, status: } },
      },
    }
  end

  it "recusa com o erro de permissao, sem gravar nem notificar" do
    marcar(ClassEnrollmentRequest::EFFECTED)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
      I18n.t("activerecord.errors.models.enrollment_request.attributes.base.cannot_effect")
    )
    expect(@cer.reload.status).to eq(ClassEnrollmentRequest::VALID)
    expect(Notifier).not_to have_received(:send_emails)
  end

  # Controle: o mesmo orientador, pelo mesmo formulario, pode invalidar.
  it "aceita a mudanca para um status que o orientador pode dar" do
    marcar(ClassEnrollmentRequest::INVALID)

    expect(response).to redirect_to(enrollment_requests_path)
    expect(@cer.reload.status).to eq(ClassEnrollmentRequest::INVALID)
    expect(Notifier).to have_received(:send_emails).once
  end
end
