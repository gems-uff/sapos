# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Entrega que falha durante a requisicao (issue #755). O formulario de
# inscricao grava (pedido de troca de e-mail, sent_email da carta) e so depois
# chama Notifier.send_emails; a confirmacao da troca faz o mesmo. A falha se
# monta no Mail::TestMailer, onde o mail.deliver! levanta, sem stub do
# Notifier: ele captura a falha de cada mensagem e devolve as nao entregues
# (issue #782), e e esse o caminho que o conserto da #755 tem de seguir.
RSpec.describe "Falha de entrega no processo seletivo", type: :request do
  before(:each) do
    @falhar = false
    allow_any_instance_of(Mail::TestMailer).to receive(:deliver!).and_wrap_original do |original, *args|
      raise Errno::EPIPE, "sendmail" if @falhar
      original.call(*args)
    end
    allow(ExceptionNotifier).to receive(:notify_exception)

    @template = create_admission_template(
      "Entrega", { "Dado" => Admissions::FormField::STRING, "Correio" => Admissions::FormField::STRING }
    )
    @template.fields.find_by!(name: "Correio").update!(sync: Admissions::FormField::SYNC_EMAIL)
    carta = create_admission_template("Carta Entrega", { "Parecer" => Admissions::FormField::STRING },
      template_type: Admissions::FormTemplate::RECOMMENDATION_LETTER)
    @processo = FactoryBot.create(
      :admission_process, name: "Entrega", simple_url: "falha-de-entrega", form_template: @template,
      letter_template: carta, min_letters: nil, max_letters: 2, require_session: false,
      start_date: Date.current - 10.days, end_date: Date.current + 10.days, edit_date: Date.current + 20.days
    )
    post admission_apply_index_path(admission_id: @processo.simple_id), params: { record: {
      name: "Pessoa", filled_form_attributes: { enable_submission: "1", fields_attributes: campos(nil, "pessoa@example.com") },
    } }
    @inscricao = Admissions::AdmissionApplication.find_by!(email: "pessoa@example.com")
    ActionMailer::Base.deliveries.clear
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  def enviados
    ActionMailer::Base.deliveries.flat_map(&:to)
  end

  def campos(inscricao, correio)
    @template.fields.order(:id).each_with_index.to_h do |campo, i|
      entrada = { form_field_id: campo.id, value: campo.name == "Correio" ? correio : "dado" }
      existente = inscricao&.filled_form&.fields&.find_by(form_field_id: campo.id)
      entrada[:id] = existente.id if existente
      [i.to_s, entrada]
    end
  end

  def enviar(correio, cartas: nil)
    record = { filled_form_attributes: { id: @inscricao.filled_form.id, enable_submission: "1",
                                         fields_attributes: campos(@inscricao, correio) } }
    record[:letter_requests_attributes] = cartas if cartas
    put admission_apply_path(admission_id: @processo.simple_id, id: @inscricao.reload.token), params: { record: record }
  end

  let(:carta) { { "0" => { name: "Rec", email: "rec@example.com" } } }

  it "controle: sem falha, o pedido de carta chega ao recomendador" do
    enviar("pessoa@example.com", cartas: carta)
    expect(enviados).to include("rec@example.com")
  end

  it "controle: o reenvio do formulario manda a carta que ainda nao foi mandada" do
    @inscricao.letter_requests.create!(name: "Rec", email: "rec@example.com",
      filled_form: Admissions::FilledForm.create!(form_template: @processo.letter_template, is_filled: false))
    enviar("pessoa@example.com")
    expect(enviados).to include("rec@example.com")
  end

  it "carta cuja mensagem nao saiu segue no proximo envio do formulario", pending: "issue #755" do
    @falhar = true
    enviar("pessoa@example.com", cartas: carta)
    @falhar = false
    enviar("pessoa@example.com")
    expect(enviados).to include("rec@example.com")
  end

  it "o candidato nao recebe erro 500 quando a entrega falha" do
    @falhar = true
    enviar("nova@example.com")
    expect(enviados).to be_empty
    expect(response.status).not_to eq(500)
  end
end
