# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A resposta obrigatória de um formulário já submetido só sai dele trocada por
# outra. Dois caminhos a tiravam sem conferência: a remoção do arquivo, que o
# CarrierWave só efetiva ao gravar, depois da validação; e a remoção da linha do
# campo (`_destroy`), que nenhuma tela manda e que a validação pulava.
RSpec.describe "Resposta obrigatoria de formulario submetido", type: :request do
  before(:each) do
    allow(Notifier).to receive(:send_emails)
    allow(ExceptionNotifier).to receive(:notify_exception)

    @template = create_admission_template("Inscricao", {
      "Obrigatorio" => { field_type: Admissions::FormField::STRING, configuration: { required: true } },
      "Documento" => { field_type: Admissions::FormField::FILE, configuration: { required: true } },
      "Anexo" => { field_type: Admissions::FormField::FILE },
    })
    @carta_template = create_admission_template(
      "Carta", { "Parecer" => { field_type: Admissions::FormField::STRING, configuration: { required: true } } },
      template_type: Admissions::FormTemplate::RECOMMENDATION_LETTER
    )
    @processo = FactoryBot.create(
      :admission_process, name: "Obrigatorias", simple_url: "obrigatorias",
      form_template: @template, letter_template: @carta_template, require_session: false,
      start_date: Date.current - 10.days, end_date: Date.current + 10.days, edit_date: Date.current + 20.days
    )
    @inscricao = create_application(@processo, name: "Pessoa", fields: {
      "Obrigatorio" => "resposta", "Documento" => { file: arquivo }, "Anexo" => { file: arquivo },
    })
  end

  def arquivo
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/user.png"), "image/png")
  end

  def campo(nome, formulario = @inscricao.filled_form)
    formulario.fields.joins(:form_field).find_by!(form_fields: { name: nome })
  end

  # O que a tela manda de cada campo, mais o que o exemplo altera.
  def enviar(alterados)
    entradas = %w[Obrigatorio Documento Anexo].each_with_index.to_h do |nome, i|
      gravado = campo(nome)
      entrada = { id: gravado.id, form_field_id: gravado.form_field_id }
      entrada[:value] = gravado.value if nome == "Obrigatorio"
      [i.to_s, entrada.merge(alterados.fetch(nome, {}))]
    end
    put admission_apply_path(admission_id: @processo.simple_id, id: @inscricao.token), params: { record: {
      filled_form_attributes: { id: @inscricao.filled_form_id, enable_submission: "1", fields_attributes: entradas },
    } }
  end

  describe "na inscricao" do
    it "recusa a remocao do arquivo obrigatorio que nao traz outro" do
      enviar("Documento" => { remove_file: "true" })

      expect(response).to have_http_status(:ok)
      expect(campo("Documento").file).to be_present
    end

    # Controle: a troca do arquivo obrigatório. Ao escolher o arquivo novo, a
    # tela desfaz a marca de remoção.
    it "aceita a troca do arquivo obrigatorio" do
      enviar("Documento" => { remove_file: "false", file: arquivo })

      expect(response).to have_http_status(:found)
      expect(campo("Documento").file).to be_present
    end

    # Controle: a remoção vale no arquivo que não é obrigatório.
    it "aceita a remocao do arquivo que nao e obrigatorio" do
      enviar("Anexo" => { remove_file: "true" })

      expect(response).to have_http_status(:found)
      expect(campo("Anexo").file).to be_blank
    end

    it "nao remove a linha do campo obrigatorio" do
      gravado = campo("Obrigatorio")

      enviar("Obrigatorio" => { _destroy: "1" })

      expect(Admissions::FilledFormField.find_by(id: gravado.id)&.value).to eq("resposta")
    end

    # Controle: a resposta obrigatória em branco é recusada.
    it "recusa a resposta obrigatoria em branco" do
      enviar("Obrigatorio" => { value: "" })

      expect(response).to have_http_status(:ok)
      expect(campo("Obrigatorio").value).to eq("resposta")
    end
  end

  describe "na carta de recomendacao" do
    before(:each) do
      @pedido = FactoryBot.create(
        :letter_request, admission_application: @inscricao, name: "Recomendador",
        filled_form: FactoryBot.create(:filled_form, form_template: @carta_template, is_filled: true)
      )
      @parecer = FactoryBot.create(
        :filled_form_field, filled_form: @pedido.filled_form, form_field: @carta_template.fields.first, value: "Recomendo"
      )
    end

    def responder(entrada)
      put admission_letter_path(admission_id: @processo.simple_id, id: @pedido.access_token), params: { record: {
        filled_form_attributes: {
          id: @pedido.filled_form.id, enable_submission: "1",
          fields_attributes: { "0" => { id: @parecer.id, form_field_id: @parecer.form_field_id }.merge(entrada) },
        },
      } }
    end

    it "nao remove a linha do campo obrigatorio" do
      responder(_destroy: "1")

      expect(Admissions::FilledFormField.find_by(id: @parecer.id)&.value).to eq("Recomendo")
    end

    # Controle: a resposta obrigatória em branco é recusada.
    it "recusa a resposta obrigatoria em branco" do
      responder(value: "")

      expect(response).to have_http_status(:ok)
      expect(@parecer.reload.value).to eq("Recomendo")
    end
  end
end
