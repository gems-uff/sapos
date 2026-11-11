# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O e-mail da inscrição é para onde o código de identificação viaja, e o do
# pedido de carta, para onde vai o link do recomendador. Texto que não é
# endereço deixa o candidato sem o código e o recomendador sem o link (issue
# #751). O navegador confere o formato no campo de e-mail da tela; o servidor
# confere de novo, porque o envio pode não vir da tela e porque o campo do
# formulário sincronizado com o e-mail é uma caixa de texto.
RSpec.describe "Formato do e-mail da inscricao", type: :request do
  NAO_SAO_ENDERECOS = {
    "sem arroba" => "pessoa.example.com",
    "com espaco no meio" => "pessoa @example.com",
    "que e uma lista" => "pessoa@example.com, outra@example.com",
    "sem dominio" => "pessoa@",
  }.freeze

  before(:each) do
    @enviados = []
    allow(Notifier).to receive(:send_emails) { |notifications:| @enviados.concat(notifications) }
    allow(ExceptionNotifier).to receive(:notify_exception)

    @template = create_admission_template("Inscricao", { "Dado" => Admissions::FormField::STRING })
    @sincronizado = create_admission_template(
      "Com e-mail", { "Dado" => Admissions::FormField::STRING, "Correio" => Admissions::FormField::STRING }
    )
    @sincronizado.fields.find_by!(name: "Correio").update!(sync: Admissions::FormField::SYNC_EMAIL)
    datas = {
      start_date: Date.current - 10.days, end_date: Date.current + 10.days, edit_date: Date.current + 20.days
    }
    @com_sessao = FactoryBot.create(
      :admission_process, name: "Com sessao", simple_url: "formato-com-sessao",
      form_template: @template, require_session: true, **datas
    )
    @sem_sessao = FactoryBot.create(
      :admission_process, name: "Sem sessao", simple_url: "formato-sem-sessao",
      form_template: @template, require_session: false, **datas
    )
    @com_campo = FactoryBot.create(
      :admission_process, name: "Com campo de e-mail", simple_url: "formato-com-campo",
      form_template: @sincronizado, require_session: false, **datas
    )
  end

  # Nome e e-mail na tela do processo.
  def pedir(processo, nome, email)
    post admission_path(processo.simple_url),
      params: { admissions_admission_application: { name: nome, email: email } }
  end

  def campos(template, inscricao, valores)
    template.fields.order(:id).each_with_index.to_h do |campo, i|
      entrada = { form_field_id: campo.id, value: valores[campo.name] }
      existente = inscricao&.filled_form&.fields&.find_by(form_field_id: campo.id)
      entrada[:id] = existente.id if existente
      [i.to_s, entrada]
    end
  end

  # Envio do formulário que cria a inscrição, em processo sem sessão.
  def inscrever(processo, valores, **extra)
    post admission_apply_index_path(admission_id: processo.simple_id), params: { record: {
      filled_form_attributes: {
        enable_submission: "1", fields_attributes: campos(processo.form_template, nil, valores),
      }, **extra,
    } }
  end

  # Envio do formulário de uma inscrição que já existe.
  def enviar(processo, inscricao, valores, **extra)
    put admission_apply_path(admission_id: processo.simple_id, id: inscricao.token), params: { record: {
      filled_form_attributes: {
        id: inscricao.filled_form.id, enable_submission: "1",
        fields_attributes: campos(processo.form_template, inscricao, valores),
      }, **extra,
    } }
  end

  def recusa_do_formato
    ERB::Util.html_escape(
      "#{Admissions::AdmissionApplication.human_attribute_name(:email)} #{I18n.t('errors.messages.invalid')}"
    )
  end

  describe "na pre-inscricao" do
    NAO_SAO_ENDERECOS.each do |caso, texto|
      it "recusa o texto #{caso}, sem criar a inscricao nem mandar mensagem" do
        expect {
          pedir(@com_sessao, "Pessoa", texto)
        }.not_to change { Admissions::AdmissionApplication.count }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(recusa_do_formato)
        expect(@enviados).to be_empty
      end
    end

    # Controle: o endereço é aceito, e o código segue para ele.
    it "aceita o endereco" do
      expect {
        pedir(@com_sessao, "Pessoa", "pessoa@example.com")
      }.to change { Admissions::AdmissionApplication.count }.by(1)
      expect(@enviados.map { |mensagem| mensagem[:to] }).to eq(["pessoa@example.com"])
    end

    # O espaço em volta não é parte do endereço: sai antes de gravar.
    it "aceita o endereco com espaco em volta, e o grava sem o espaco" do
      pedir(@com_sessao, "Pessoa", "  pessoa@example.com ")

      expect(Admissions::AdmissionApplication.find_by(admission_process: @com_sessao)&.email).to eq("pessoa@example.com")
    end
  end

  describe "no formulario que cria a inscricao" do
    NAO_SAO_ENDERECOS.each do |caso, texto|
      it "recusa no campo de e-mail da tela o texto #{caso}" do
        expect {
          inscrever(@sem_sessao, { "Dado" => "dado" }, name: "Pessoa", email: texto)
        }.not_to change { Admissions::AdmissionApplication.count }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(recusa_do_formato)
        expect(@enviados).to be_empty
      end

      it "recusa no campo sincronizado com o e-mail o texto #{caso}" do
        expect {
          inscrever(@com_campo, { "Dado" => "dado", "Correio" => texto }, name: "Pessoa")
        }.not_to change { Admissions::AdmissionApplication.count }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(recusa_do_formato)
        expect(@enviados).to be_empty
      end
    end

    # Controles: o mesmo envio, com endereço.
    it "aceita o endereco no campo de e-mail da tela" do
      inscrever(@sem_sessao, { "Dado" => "dado" }, name: "Pessoa", email: "pessoa@example.com")

      expect(Admissions::AdmissionApplication.find_by(email: "pessoa@example.com")&.filled_form&.is_filled).to be(true)
    end

    it "aceita o endereco no campo sincronizado com o e-mail" do
      inscrever(@com_campo, { "Dado" => "dado", "Correio" => "pessoa@example.com" }, name: "Pessoa")

      expect(Admissions::AdmissionApplication.find_by(email: "pessoa@example.com")&.filled_form&.is_filled).to be(true)
    end

    # O campo sincronizado é conferido também pelo navegador, como o campo de
    # e-mail da tela.
    it "oferece o campo sincronizado como campo de e-mail" do
      get new_admission_apply_path(admission_id: @com_campo.simple_id)

      correio = @sincronizado.fields.find_by!(name: "Correio")
      pagina = Nokogiri::HTML(response.body)
      marca = pagina.css("input[type=hidden][name$='[form_field_id]']").find { |e| e["value"] == correio.id.to_s }
      campo = pagina.at_css("input[name='#{marca['name'].delete_suffix('[form_field_id]')}[value]']")

      expect(campo["type"]).to eq("email")
    end
  end

  # Inscrição gravada antes da conferência pode ter endereço fora do formato.
  # O candidato tem de conseguir editar o resto; a conferência vale para o
  # endereço novo ou alterado.
  describe "na inscricao que ja tem endereco fora do formato" do
    before(:each) do
      @inscricao = create_application(@sem_sessao, name: "Antiga", email: "antiga@example.com", fields: { "Dado" => "dado" })
      @inscricao.update_column(:email, "antiga sem formato")
    end

    it "deixa o candidato editar os outros campos" do
      enviar(@sem_sessao, @inscricao, { "Dado" => "outro dado" })

      expect(response).to redirect_to(admission_apply_path(admission_id: @sem_sessao.simple_id, id: @inscricao.token))
      expect(@inscricao.reload.filled_form.fields.first.value).to eq("outro dado")
      expect(@inscricao.email).to eq("antiga sem formato")
    end
  end

  describe "no e-mail do recomendador" do
    before(:each) do
      letter_template = FactoryBot.create(:form_template, name: "Carta", template_type: "Carta de Recomendação")
      @sem_sessao.update!(letter_template: letter_template, min_letters: 0, max_letters: 2)
      @inscricao = create_application(@sem_sessao, name: "Pessoa", email: "pessoa@example.com", fields: { "Dado" => "dado" })
    end

    def pedir_carta(email)
      enviar(
        @sem_sessao, @inscricao, { "Dado" => "dado" },
        letter_requests_attributes: { "0" => { name: "Recomendador", email: email } }
      )
    end

    NAO_SAO_ENDERECOS.each do |caso, texto|
      it "recusa o texto #{caso}, sem criar o pedido de carta nem mandar o link" do
        expect { pedir_carta(texto) }.not_to change { Admissions::LetterRequest.count }

        expect(response).to have_http_status(:ok)
        expect(@enviados).to be_empty
      end
    end

    # Controle: o mesmo pedido, com endereço.
    it "aceita o endereco e manda o link" do
      expect { pedir_carta("recomendador@example.com") }.to change { Admissions::LetterRequest.count }.by(1)

      expect(@enviados.map { |mensagem| mensagem[:to] }).to include("recomendador@example.com")
    end
  end
end
