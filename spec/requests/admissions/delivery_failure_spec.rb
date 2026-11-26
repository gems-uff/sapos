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
    @falhar_para = []
    allow_any_instance_of(Mail::TestMailer).to receive(:deliver!).and_wrap_original do |original, mail|
      raise Errno::EPIPE, "sendmail" if @falhar || Array(mail.to).intersect?(@falhar_para)
      original.call(mail)
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

  it "carta cuja mensagem nao saiu segue no proximo envio do formulario" do
    @falhar = true
    enviar("pessoa@example.com", cartas: carta)
    @falhar = false
    enviar("pessoa@example.com")
    expect(enviados).to include("rec@example.com")
  end

  it "controle: carta entregue fica marcada e nao segue de novo no proximo envio" do
    enviar("pessoa@example.com", cartas: carta)
    expect(@inscricao.letter_requests.reload.map(&:sent_email)).to eq(["rec@example.com"])
    expect(flash[:alert]).to be_nil
    ActionMailer::Base.deliveries.clear
    enviar("pessoa@example.com")
    expect(enviados).to eq(["pessoa@example.com"])
  end

  context "com duas cartas, uma delas sem entrega" do
    let(:cartas) do
      { "0" => { name: "Rec Um", email: "um@example.com" }, "1" => { name: "Rec Dois", email: "dois@example.com" } }
    end

    before(:each) do
      @falhar_para = ["dois@example.com"]
      enviar("pessoa@example.com", cartas: cartas)
    end

    it "a tela grava a inscricao e nomeia so o recomendador cuja carta nao saiu" do
      expect(response).to redirect_to(admission_apply_path(admission_id: @processo.simple_id, id: @inscricao.reload.token))
      expect(flash[:notice]).to eq(I18n.t("admissions.apply.update.edit_notice"))
      expect(flash[:alert]).to include("Rec Dois (dois@example.com)")
      expect(flash[:alert]).not_to include("um@example.com")
    end

    it "so a carta entregue fica marcada como enviada" do
      marcadas = @inscricao.letter_requests.reload.to_h { |pedido| [pedido.email, pedido.sent_email] }
      expect(marcadas).to eq("um@example.com" => "um@example.com", "dois@example.com" => nil)
    end

    it "o proximo envio manda so a carta que nao saiu, e a tela deixa de avisar" do
      follow_redirect! # o aviso do primeiro envio e mostrado e sai do flash
      @falhar_para = []
      ActionMailer::Base.deliveries.clear
      enviar("pessoa@example.com")
      expect(enviados).to contain_exactly("pessoa@example.com", "dois@example.com")
      expect(flash[:alert]).to be_nil
    end
  end

  it "inscricao nova: o aviso da carta que nao saiu acompanha o do codigo" do
    @falhar_para = ["rec@example.com"]
    post admission_apply_index_path(admission_id: @processo.simple_id), params: { record: {
      name: "Outra", letter_requests_attributes: carta,
      filled_form_attributes: { enable_submission: "1", fields_attributes: campos(nil, "outra@example.com") },
    } }
    expect(response).to redirect_to(admissions_path)
    expect(flash[:notice]).to eq(I18n.t("admissions.apply.update.new_token_sent", email: "outra@example.com"))
    expect(flash[:alert]).to include("Rec (rec@example.com)")
    nova = Admissions::AdmissionApplication.find_by!(email: "outra@example.com")
    expect(nova.letter_requests.map(&:sent_email)).to eq([nil])
  end

  it "com o envio desligado, a carta fica pendente e a tela avisa" do
    allow(CustomVariable).to receive(:redirect_email).and_return("")
    enviar("pessoa@example.com", cartas: carta)
    expect(@inscricao.letter_requests.reload.map(&:sent_email)).to eq([nil])
    expect(flash[:alert]).to include("Rec (rec@example.com)")
  end

  it "o candidato nao recebe erro 500 quando a entrega falha" do
    @falhar = true
    enviar("nova@example.com")
    expect(enviados).to be_empty
    expect(response.status).not_to eq(500)
  end
end
