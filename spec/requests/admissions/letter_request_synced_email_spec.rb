# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O e-mail do pedido de carta é para onde o link da carta viaja. Na tela
# interna ele chega por dois campos: o do pedido e, quando o modelo da carta
# tem um, o campo da carta sincronizado com o e-mail. A regra do endereço
# (LetterRequest#follow_email_change) vale para o endereço que fica, venha de
# onde vier: a carta já respondida não muda de endereço, e a que muda ganha
# outro código de acesso.
RSpec.describe "E-mail do pedido de carta pelo campo sincronizado da carta", type: :request do
  before(:each) do
    @enviados = []
    allow(Notifier).to receive(:send_emails) { |notifications:| @enviados.concat(notifications) }

    inscricao = create_admission_template("Inscricao", { "Dado" => Admissions::FormField::STRING })
    @carta = create_admission_template(
      "Carta", {
        "Parecer" => Admissions::FormField::STRING,
        "Correio" => { field_type: Admissions::FormField::STRING, sync: Admissions::FormField::SYNC_EMAIL },
        "Nome" => { field_type: Admissions::FormField::STRING, sync: Admissions::FormField::SYNC_NAME },
      }, template_type: Admissions::FormTemplate::RECOMMENDATION_LETTER
    )
    @processo = FactoryBot.create(
      :admission_process, name: "Com carta", simple_url: "carta-sincronizada",
      form_template: inscricao, letter_template: @carta, min_letters: 0, max_letters: 2, staff_can_edit: true,
      start_date: Date.current - 10.days, end_date: Date.current + 10.days, edit_date: Date.current + 20.days
    )
    @inscricao = create_application(@processo, name: "Candidata", fields: { "Dado" => "dado" })
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "carta-admin@ic.uff.br", "Admin")
  end

  def pedido_de_carta(respondida:)
    formulario = FactoryBot.create(:filled_form, form_template: @carta, is_filled: respondida)
    fill_fields(formulario, {
      "Parecer" => (respondida ? "resposta do recomendador" : nil),
      "Correio" => "recomendador@example.com", "Nome" => "Recomendador",
    })
    FactoryBot.create(
      :letter_request, admission_application: @inscricao, name: "Recomendador",
      email: "recomendador@example.com", filled_form: formulario
    )
  end

  def campo(pedido, nome)
    pedido.filled_form.fields.joins(:form_field).find_by!(form_fields: { name: nome })
  end

  # A edição total (override), com o formulário da carta habilitado na
  # submissão; `pedido_email` e `pedido_nome` são os campos do próprio pedido.
  def salvar(pedido, correio:, pedido_email: nil, pedido_nome: nil)
    entrada = {
      id: pedido.id, name: pedido_nome || pedido.name, email: pedido_email || pedido.email,
      filled_form_attributes: {
        id: pedido.filled_form.id, enable_submission: "1",
        fields_attributes: %w[Parecer Correio Nome].each_with_index.to_h do |nome, i|
          gravado = campo(pedido, nome)
          valor = nome == "Correio" ? correio : gravado.value
          [i.to_s, { id: gravado.id, form_field_id: gravado.form_field_id, value: valor }]
        end,
      },
    }
    put admission_application_path(@inscricao), xhr: true, params: {
      can_edit_override: "1", record: { letter_requests_attributes: { "0" => entrada } },
    }
  end

  describe "na carta ja respondida" do
    before(:each) do
      @pedido = pedido_de_carta(respondida: true)
      @codigo = @pedido.access_token
    end

    it "nao muda o endereco pelo campo sincronizado da carta" do
      salvar(@pedido, correio: "outra-caixa@example.com")

      expect(@pedido.reload.email).to eq("recomendador@example.com")
      expect(@pedido.access_token).to eq(@codigo)
      expect(campo(@pedido, "Correio").value).to eq("recomendador@example.com")
      expect(@enviados).to be_empty
    end

    # Controle: o campo do próprio pedido, que já era reposto.
    it "nao muda o endereco pelo campo do pedido" do
      salvar(@pedido, correio: "recomendador@example.com", pedido_email: "outra-caixa@example.com")

      expect(@pedido.reload.email).to eq("recomendador@example.com")
      expect(@pedido.access_token).to eq(@codigo)
    end
  end

  describe "na carta ainda nao respondida" do
    before(:each) do
      @pedido = pedido_de_carta(respondida: false)
      @codigo = @pedido.access_token
    end

    it "muda o endereco pelo campo sincronizado da carta, com outro codigo, que segue para o endereco novo" do
      salvar(@pedido, correio: "certo@example.com")

      expect(@pedido.reload.email).to eq("certo@example.com")
      expect(@pedido.access_token).not_to eq(@codigo)
      expect(@enviados.map { |mensagem| mensagem[:to] }).to eq(["certo@example.com"])
    end

    # A correção feita no campo do pedido não se perde para o campo da carta,
    # que a tela manda junto com o endereço de antes.
    it "fica com o endereco corrigido no campo do pedido, e o campo da carta o acompanha" do
      salvar(@pedido, correio: "recomendador@example.com", pedido_email: "certo@example.com")

      expect(@pedido.reload.email).to eq("certo@example.com")
      expect(campo(@pedido, "Correio").value).to eq("certo@example.com")
      expect(@pedido.access_token).not_to eq(@codigo)
      expect(@enviados.map { |mensagem| mensagem[:to] }).to eq(["certo@example.com"])
    end

    # O mesmo vale para os outros campos do pedido que a carta sincroniza, e
    # para a correção só da caixa do endereço.
    it "fica com o nome corrigido no campo do pedido, e o campo da carta o acompanha" do
      salvar(@pedido, correio: "recomendador@example.com", pedido_nome: "Recomendador Certo")

      expect(@pedido.reload.name).to eq("Recomendador Certo")
      expect(campo(@pedido, "Nome").value).to eq("Recomendador Certo")
    end

    it "fica com a caixa do endereco corrigida no campo do pedido, sem trocar o codigo" do
      salvar(@pedido, correio: "recomendador@example.com", pedido_email: "Recomendador@Example.com")

      expect(@pedido.reload.email).to eq("Recomendador@Example.com")
      expect(@pedido.access_token).to eq(@codigo)
    end

    # Controle: sem mudança de endereço, o código fica e nada é enviado.
    it "mantem o codigo quando o endereco nao muda" do
      salvar(@pedido, correio: "recomendador@example.com")

      expect(@pedido.reload.email).to eq("recomendador@example.com")
      expect(@pedido.access_token).to eq(@codigo)
      expect(@enviados).to be_empty
    end
  end
end
