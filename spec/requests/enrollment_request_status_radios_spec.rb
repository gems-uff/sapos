# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Radios de situacao de cada disciplina no pedido de inscricao (#720). O
# orientador nao pode efetivar, nem mexer em disciplina ja efetivada; o
# EnrollmentRequestsHelper#class_request_attribute marca esses radios como
# somente leitura, e so o administrador abria o formulario na suite.
RSpec.describe "Pedido de inscricao: radios de situacao", type: :request do
  before(:each) do
    @level = FactoryBot.create(:level)
    @professor = FactoryBot.create(:professor, name: "Orientador Radios")
    FactoryBot.create(
      :advisement_authorization, professor: @professor, level: @level,
      start_date: Date.new(2019, 1, 1)
    )
    @enrollment = FactoryBot.create(
      :enrollment, level: @level, admission_date: Date.new(2020, 3, 1),
      enrollment_status: FactoryBot.create(:enrollment_status, user: true)
    )
    FactoryBot.create(:advisement, enrollment: @enrollment, professor: @professor)
    @pedido = FactoryBot.create(:enrollment_request, enrollment: @enrollment, year: 2020, semester: 1)
  end

  def disciplina(status)
    turma = FactoryBot.create(:course_class, professor: @professor, year: 2020, semester: 1)
    FactoryBot.create(
      :class_enrollment_request, enrollment_request: @pedido, course_class: turma, status: status
    )
  end

  # Atributos de cada radio da disciplina, por situacao.
  def radios(cer)
    Nokogiri::HTML(response.body)
      .css("input[type='radio'][name='record[class_enrollment_requests][#{cer.id}][status]']")
      .index_by { |radio| radio["value"] }
  end

  describe "orientador" do
    before(:each) do
      sign_in create_confirmed_user(
        [FactoryBot.create(:role_professor)], "orientador_radios@ic.uff.br", "Orientador",
        professor: @professor
      )
    end

    it "nao pode efetivar a disciplina pedida, mas pode mudar as outras situacoes" do
      cer = disciplina(ClassEnrollmentRequest::REQUESTED)

      get edit_enrollment_request_path(@pedido)

      expect(response).to have_http_status(:ok)
      efetivada = radios(cer)[ClassEnrollmentRequest::EFFECTED]
      expect(efetivada["readonly"]).to eq("readonly")
      expect(efetivada["disabled"]).to eq("disabled")
      (ClassEnrollmentRequest::STATUSES - [ClassEnrollmentRequest::EFFECTED]).each do |status|
        expect(radios(cer)[status]["readonly"]).to be_nil, status
      end
      expect(radios(cer)[ClassEnrollmentRequest::REQUESTED]["checked"]).to eq("checked")
    end

    # Ja efetivada, a disciplina fica toda somente leitura; o radio marcado
    # nao e desabilitado, para continuar indo no formulario.
    it "nao muda a disciplina ja efetivada" do
      cer = disciplina(ClassEnrollmentRequest::EFFECTED)

      get edit_enrollment_request_path(@pedido)

      expect(response).to have_http_status(:ok)
      radios(cer).each do |status, radio|
        expect(radio["readonly"]).to eq("readonly"), status
        expected_disabled = status == ClassEnrollmentRequest::EFFECTED ? nil : "disabled"
        expect(radio["disabled"]).to eq(expected_disabled), status
      end
      expect(radios(cer)[ClassEnrollmentRequest::EFFECTED]["class"]).to include("effected-item")
    end
  end

  it "o administrador muda qualquer situacao, inclusive efetivar" do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm_radios@ic.uff.br", "Adm"
    )
    cer = disciplina(ClassEnrollmentRequest::REQUESTED)

    get edit_enrollment_request_path(@pedido)

    expect(response).to have_http_status(:ok)
    expect(radios(cer).keys).to match_array(ClassEnrollmentRequest::STATUSES)
    radios(cer).each do |status, radio|
      expect(radio["readonly"]).to be_nil, status
      expect(radio["disabled"]).to be_nil, status
    end
  end
end
