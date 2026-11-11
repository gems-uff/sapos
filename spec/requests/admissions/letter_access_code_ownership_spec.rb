# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O código de acesso da carta é a credencial do recomendador, e viaja por
# e-mail para o endereço do pedido de carta. O candidato edita os pedidos da
# própria inscrição, inclusive o endereço: quando ele muda, o código muda
# junto, e a carta que já foi preenchida não troca de endereço -- o link novo
# abriria as respostas do recomendador numa caixa que o candidato escolheu.
RSpec.describe "Posse do codigo de acesso da carta", type: :request do
  before(:each) do
    @enviadas = []
    allow(Notifier).to receive(:send_emails) { |notifications:| @enviadas.concat(notifications) }

    inscricao = create_admission_template("Inscricao", { "Dado" => Admissions::FormField::STRING })
    @carta = create_admission_template(
      "Carta", { "Parecer" => Admissions::FormField::STRING },
      template_type: Admissions::FormTemplate::RECOMMENDATION_LETTER
    )
    @process = FactoryBot.create(
      :admission_process, name: "Mestrado das Cartas", simple_url: "posse-carta",
      form_template: inscricao, letter_template: @carta, min_letters: 1, max_letters: 2, require_session: false,
      start_date: Date.current - 10.days, end_date: Date.current + 10.days, edit_date: Date.current + 20.days
    )
    @campo = inscricao.fields.first
    post admission_apply_index_path(admission_id: @process.simple_id), params: { record: {
      name: "Candidata", email: "candidata@example.com",
      filled_form_attributes: {
        enable_submission: "1", fields_attributes: { "0" => { form_field_id: @campo.id, value: "dado" } },
      },
      letter_requests_attributes: { "0" => { name: "Recomendador", email: "recomendador@example.com" } },
    } }
    @inscricao = Admissions::AdmissionApplication.find_by!(email: "candidata@example.com")
    @pedido = @inscricao.letter_requests.first
    @enviadas.clear
  end

  def recomendador_preenche(texto)
    put admission_letter_path(admission_id: @process.simple_id, id: @pedido.access_token), params: { record: {
      name: @pedido.name, email: @pedido.email,
      filled_form_attributes: {
        id: @pedido.filled_form.id, enable_submission: "1",
        fields_attributes: { "0" => { form_field_id: @carta.fields.first.id, value: texto } },
      },
    } }
    expect(@pedido.reload.is_filled).to be(true)
  end

  # A edição da inscrição pelo candidato, trocando o e-mail do pedido de carta.
  def candidato_troca_o_email_do_pedido(novo)
    existente = @inscricao.filled_form.fields.find_by(form_field_id: @campo.id)
    put admission_apply_path(admission_id: @process.simple_id, id: @inscricao.token), params: { record: {
      filled_form_attributes: {
        id: @inscricao.filled_form.id, enable_submission: "1",
        fields_attributes: { "0" => { id: existente.id, form_field_id: @campo.id, value: "dado" } },
      },
      letter_requests_attributes: { "0" => { id: @pedido.id, name: @pedido.name, email: novo } },
    } }
  end

  def abre_a_carta?(codigo)
    get admission_letter_path(admission_id: @process.simple_id, id: codigo)
    response.successful?
  end

  context "com a carta ja preenchida" do
    before(:each) { recomendador_preenche("resposta reservada do recomendador") }

    it "nao leva o pedido, nem o link, para o endereco que o candidato escolheu" do
      codigo = @pedido.access_token

      candidato_troca_o_email_do_pedido("caixa-do-candidato@example.com")

      expect(@pedido.reload.email).to eq("recomendador@example.com")
      expect(@pedido.access_token).to eq(codigo)
      expect(@enviadas.map { |mensagem| mensagem[:to] }).not_to include("caixa-do-candidato@example.com")
      expect(@enviadas.map { |mensagem| mensagem[:body] }.join).not_to include(codigo)
    end
  end

  context "com a carta ainda por preencher" do
    it "troca o codigo de acesso junto com o endereco, e o antigo deixa de abrir a carta" do
      antigo = @pedido.access_token

      candidato_troca_o_email_do_pedido("outro-recomendador@example.com")

      novo = @pedido.reload.access_token
      expect(@pedido.email).to eq("outro-recomendador@example.com")
      expect(novo).not_to eq(antigo)
      mensagem = @enviadas.find { |m| m[:to] == "outro-recomendador@example.com" }
      expect(mensagem[:body]).to include(novo)
      expect(abre_a_carta?(antigo)).to be(false)
      expect(abre_a_carta?(novo)).to be(true)
    end

    # Controle: sem trocar o endereço, o código fica e nenhuma mensagem sai.
    it "mantem o codigo quando a edicao nao troca o endereco" do
      antigo = @pedido.access_token

      candidato_troca_o_email_do_pedido("recomendador@example.com")

      expect(@pedido.reload.access_token).to eq(antigo)
      expect(@enviadas.map { |mensagem| mensagem[:subject] }).not_to include("Carta de recomendação solicitada")
    end
  end
end
