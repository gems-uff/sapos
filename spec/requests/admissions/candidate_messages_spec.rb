# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# As mensagens do processo seletivo, pelos modelos embutidos — issue #749.
#
# O Liquid devolve vazio para a variável que o drop não define, e a mensagem
# sai com um buraco no lugar: "Sua inscrição no edital de seleção  foi
# realizada". Nenhum erro, nenhum log. Aqui o candidato percorre o fluxo e cada
# mensagem que ele e o recomendador recebem tem de dizer de que edital fala.
RSpec.describe "Mensagens do processo seletivo pelos modelos embutidos", type: :request do
  before(:each) do
    @enviadas = []
    allow(Notifier).to receive(:send_emails) { |notifications:| @enviadas.concat(notifications) }

    inscricao = create_admission_template("Inscricao", { "Dado" => Admissions::FormField::STRING })
    carta = create_admission_template(
      "Carta", { "Parecer" => Admissions::FormField::STRING },
      template_type: Admissions::FormTemplate::RECOMMENDATION_LETTER
    )
    @process = FactoryBot.create(
      :admission_process, name: "Mestrado das Mensagens", simple_url: "mensagens",
      form_template: inscricao, letter_template: carta, min_letters: 1, max_letters: 1, require_session: true,
      start_date: Date.current - 10.days, end_date: Date.current + 10.days, edit_date: Date.current + 20.days
    )
    @campo = inscricao.fields.first
  end

  def assunto(texto)
    @enviadas.select { |mensagem| mensagem[:subject] == texto }
  end

  def enviar_formulario(inscricao, valor, cartas: {})
    existente = inscricao.filled_form.fields.find_by(form_field_id: @campo.id)
    campo = { form_field_id: @campo.id, value: valor }
    campo[:id] = existente.id if existente
    put admission_apply_path(admission_id: @process.simple_id, id: inscricao.token), params: { record: {
      filled_form_attributes: { id: inscricao.filled_form.id, enable_submission: "1", fields_attributes: { "0" => campo } },
      letter_requests_attributes: cartas,
    } }
  end

  it "diz o nome do edital em cada mensagem do candidato e do recomendador" do
    post admission_path(@process.simple_url),
      params: { admissions_admission_application: { name: "Pessoa", email: "pessoa@example.com" } }
    inscricao = Admissions::AdmissionApplication.find_by!(email: "pessoa@example.com")
    post find_admissions_path, params: {
      admissions_admission_application: { email: "pessoa@example.com", token: inscricao.token, _source: @process.simple_id },
    }
    enviar_formulario(inscricao, "primeiro", cartas: { "0" => { name: "Rec", email: "rec@example.com" } })
    expect(inscricao.reload.filled_form.is_filled).to be(true)
    enviar_formulario(inscricao, "segundo")
    post find_admissions_path, params: {
      admissions_admission_application: { email: "pessoa@example.com", token: "forgot", _source: @process.simple_id },
    }

    esperadas = {
      "Código de identificação da inscrição" => "pessoa@example.com",
      "Inscrição realizada" => "pessoa@example.com",
      "Carta de recomendação solicitada" => "rec@example.com",
      "Inscrição em processo seletivo alterada" => "pessoa@example.com",
      "Recuperação de código de inscrição" => "pessoa@example.com",
    }
    esperadas.each do |texto, destinatario|
      mensagens = assunto(texto)
      expect(mensagens.size).to eq(1), "#{texto}: #{mensagens.size} mensagens"
      expect(mensagens.first[:to]).to eq(destinatario), texto
      expect(mensagens.first[:body]).to include(@process.title), texto
    end
  end

  # O que acusa o buraco de qualquer variável sem valor: duas palavras
  # separadas por dois espaços onde o modelo tinha {{ ... }} entre elas.
  it "nao deixa buraco de variavel sem valor na mensagem de inscricao realizada" do
    inscricao = create_application(@process, name: "Pessoa", email: "pessoa@example.com", filled: false)
    post find_admissions_path, params: {
      admissions_admission_application: { email: "pessoa@example.com", token: inscricao.token, _source: @process.simple_id },
    }
    enviar_formulario(inscricao, "primeiro", cartas: { "0" => { name: "Rec", email: "rec@example.com" } })

    corpo = assunto("Inscrição realizada").first[:body]
    expect(corpo).to include("edital de seleção #{@process.title} foi realizada")
    expect(corpo).not_to match(/\S  \S/)
  end
end
