# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Na fase que deixa a comissão editar o candidato, a tela interna mostrava ao
# membro o formulário de cada carta como editável e submetido, inclusive o da
# carta que o recomendador ainda não respondeu. Qualquer gravação do membro
# marcava essas cartas como recebidas, vazias -- ou, com campo obrigatório na
# carta, era recusada inteira. Quem responde a carta é o recomendador; pela
# tela interna, só quem tem a edição total a preenche no lugar dele.
RSpec.describe "Carta nao respondida na edicao da candidatura pela comissao", type: :request do
  before(:each) do
    allow(Notifier).to receive(:send_emails)

    inscricao = create_admission_template("Inscricao", { "Dado" => Admissions::FormField::STRING })
    @carta = create_admission_template(
      "Carta", { "Parecer" => { field_type: Admissions::FormField::STRING, configuration: { required: true } } },
      template_type: Admissions::FormTemplate::RECOMMENDATION_LETTER
    )
    @processo = create_closed_admission_process(
      inscricao, simple_url: "carta-comissao", letter_template: @carta, min_letters: 0, max_letters: 2,
      staff_can_edit: true
    )
    @parecer_do_membro = create_admission_template("Parecer do membro", { "Nota" => Admissions::FormField::NUMBER })
    @fase = add_phase(@processo, 1, member_form: @parecer_do_membro, can_edit_candidate: true)
    @membro = professor_user("carta-membro@ic.uff.br")
    add_committee(@fase, [@membro])
    @inscricao = create_application(@processo, name: "Candidata", fields: { "Dado" => "dado" }, admission_phase: @fase)
    @fase.create_pendencies_for_candidate(@inscricao)
    @respondida = pedido_de_carta("Respondeu", "resposta do recomendador")
    @aguardando = pedido_de_carta("Nao respondeu", nil)
  end

  def pedido_de_carta(nome, resposta)
    formulario = FactoryBot.create(:filled_form, form_template: @carta, is_filled: resposta.present?)
    fill_fields(formulario, { "Parecer" => resposta }) if resposta
    FactoryBot.create(
      :letter_request, admission_application: @inscricao, name: nome,
      email: "#{nome.parameterize}@example.com", filled_form: formulario
    )
  end

  # O que a tela manda de um pedido de carta com o formulário editável.
  def carta_enviada(pedido, parecer, **marca)
    campo = pedido.filled_form.fields.first
    entrada = { form_field_id: @carta.fields.first.id, value: parecer }
    entrada[:id] = campo.id if campo
    {
      id: pedido.id, name: pedido.name, email: pedido.email,
      filled_form_attributes: { id: pedido.filled_form.id, **marca, fields_attributes: { "0" => entrada } },
    }
  end

  def nota_do_membro
    {
      user_id: @membro.id, admission_phase_id: @fase.id,
      filled_form_attributes: {
        enable_submission: "1",
        fields_attributes: { "0" => { form_field_id: @parecer_do_membro.fields.first.id, value: "9" } },
      },
    }
  end

  def formularios_de_carta_na_tela
    get edit_admission_application_path(@inscricao), env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }
    expect(response).to have_http_status(:ok)
    Nokogiri::HTML(response.body)
      .css("input[name^='record[letter_requests_attributes]'][name$='[filled_form_attributes][enable_submission]']").size
  end

  describe "para o membro da comissao" do
    before(:each) { sign_in @membro }

    def gravar(cartas)
      put admission_application_path(@inscricao), xhr: true, params: {
        can_edit_override: "",
        record: { letter_requests_attributes: cartas, evaluations_attributes: { "0" => nota_do_membro } },
      }
    end

    it "nao oferece o formulario da carta que ainda nao foi respondida" do
      expect(formularios_de_carta_na_tela).to eq(1)
    end

    it "nao marca como recebida a carta que ainda nao foi respondida, nem grava resposta nela" do
      gravar(
        "0" => carta_enviada(@respondida, "resposta do recomendador", enable_submission: "1"),
        "1" => carta_enviada(@aguardando, "escrito pelo membro", enable_submission: "1")
      )

      expect(@aguardando.reload.is_filled).to be(false)
      expect(@aguardando.filled_form.fields.pluck(:value)).not_to include("escrito pelo membro")
    end

    it "grava o parecer do membro com carta ainda nao respondida no processo" do
      gravar(
        "0" => carta_enviada(@respondida, "resposta do recomendador", enable_submission: "1"),
        "1" => carta_enviada(@aguardando, "", enable_submission: "1")
      )

      avaliacao = @inscricao.evaluations.find_by!(user: @membro)
      expect(avaliacao.filled_form.is_filled).to be(true)
      expect(avaliacao.filled_form.fields.pluck(:value)).to include("9")
      expect(@respondida.reload.is_filled).to be(true)
    end
  end

  # Controle: quem tem a edição total preenche a carta no lugar do
  # recomendador, habilitando o formulário dela na submissão.
  describe "para quem tem a edicao total" do
    before(:each) do
      sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "carta-comissao-admin@ic.uff.br", "Admin")
    end

    it "oferece o formulario das duas cartas" do
      get edit_admission_application_path(@inscricao), params: { override: true },
        env: { "REMOTE_ADDR" => RouteProbe::REMOTE_ADDR }

      expect(Nokogiri::HTML(response.body).css(
        "input[type=checkbox][name^='record[letter_requests_attributes]'][name$='[filled_form_attributes][enable_submission]']"
      ).size).to eq(2)
    end

    it "marca como recebida a carta que preenche" do
      put admission_application_path(@inscricao), xhr: true, params: {
        can_edit_override: "1",
        record: { letter_requests_attributes: {
          "0" => carta_enviada(@aguardando, "recebida em papel", enable_submission: "1"),
        } },
      }

      expect(@aguardando.reload.is_filled).to be(true)
      expect(@aguardando.filled_form.fields.pluck(:value)).to include("recebida em papel")
    end
  end
end
