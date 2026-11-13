# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Pedidos de inscricao em disciplina: so o caminho por js do efetivar em lote e
# os set_* que mudam o status estavam cobertos. Sem cobertura (#720): o set_*
# que nao muda nada (status igual, ou matricula trancada no periodo), as telas
# show_effect e help abertas sem js e o efetivar em lote sem js. As respostas
# em iframe, que a tela nunca pede, entram como defesa.
RSpec.describe "Efetivacao de pedidos de inscricao em disciplina", type: :request do
  before(:each) do
    @enrollment = FactoryBot.create(:enrollment, admission_date: Date.new(2019, 3, 1))
    @course_class = FactoryBot.create(:course_class, year: 2020, semester: 1)
    @pedido = FactoryBot.create(:enrollment_request, enrollment: @enrollment, year: 2020, semester: 1)
    @cer = FactoryBot.create(
      :class_enrollment_request, enrollment_request: @pedido, course_class: @course_class,
      status: ClassEnrollmentRequest::VALID
    )
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm.efetivar@ic.uff.br", "Adm")
    allow(Notifier).to receive(:send_emails)
  end

  describe "set_* que nao muda o pedido" do
    it "com o mesmo status, avisa que nada mudou" do
      put set_valid_class_enrollment_request_path(@cer)

      expect(response).to redirect_to(class_enrollment_requests_path)
      expect(flash[:info]).to eq(I18n.t("class_enrollment_request.valid.applied", count: 0))
      expect(flash[:error]).to eq([])
    end

    # Lista desatualizada: o trancamento criado depois de a lista abrir ja
    # invalidou o pedido, e o efetivar esbarra na validacao do trancamento.
    it "com a matricula trancada no periodo, avisa e traz o erro da validacao" do
      FactoryBot.create(:enrollment_hold, enrollment: @enrollment, year: 2020, semester: 1)
      expect(@cer.reload.status).to eq(ClassEnrollmentRequest::INVALID)

      put set_effected_class_enrollment_request_path(@cer)

      expect(response).to redirect_to(class_enrollment_requests_path)
      expect(@cer.reload.status).to eq(ClassEnrollmentRequest::INVALID)
      expect(flash[:info]).to eq(I18n.t("class_enrollment_request.effected.applied", count: 0))
      expect(flash[:error]).to eq([
        ClassEnrollmentRequest.new.errors.full_message(
          :enrollment, I18n.t("activerecord.errors.models.class_enrollment_request.attributes.enrollment.enrollment_is_held")
        )
      ])
      expect(Notifier).not_to have_received(:send_emails)
    end

    # Defesa: set_* e action link put, nunca formulario com upload.
    it "com iframe=true responde ao frame pai" do
      put set_valid_class_enrollment_request_path(@cer), params: { iframe: "true" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("with(window.parent)")
    end
  end

  describe "telas abertas sem js" do
    it "show_effect mostra quantos pedidos da lista podem ser efetivados" do
      get show_effect_class_enrollment_requests_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("class_enrollment_request.effected.count", count: 1))
      form = Nokogiri::HTML(response.body).at_css("form.effect")
      expect(form["action"]).to start_with(effect_class_enrollment_requests_path)
      expect(form["data-remote"]).to be_nil
    end

    it "help mostra a ajuda compartilhada com as solicitacoes" do
      get help_class_enrollment_requests_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Durante a inscrição online")
    end
  end

  describe "POST effect" do
    it "sem js efetiva a lista e volta para ela com a contagem" do
      post effect_class_enrollment_requests_path

      expect(response).to redirect_to(class_enrollment_requests_path)
      expect(flash[:info]).to eq(I18n.t("class_enrollment_request.effected.applied", count: 1))
      expect(@cer.reload.status).to eq(ClassEnrollmentRequest::EFFECTED)
      expect(Notifier).to have_received(:send_emails).once
    end

    # Defesa: _effect usa form_tag, entao a tela nunca pede iframe.
    it "com iframe=true efetiva e responde ao frame pai" do
      post effect_class_enrollment_requests_path, params: { iframe: "true" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("with(window.parent)")
      expect(@cer.reload.status).to eq(ClassEnrollmentRequest::EFFECTED)
    end
  end
end
