# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Campo de aluno que tem widget proprio perde o required no caminho ate o HTML.
#
# _as_student_field calcula options[:required] a partir da configuracao e
# entrega ao active_scaffold_input_for. Quando a coluna tem override -- e
# identity_issuing_place tem, custom_identity_issuing_place_form_column --, quem
# monta o input e o parcial do widget, que le de options apenas name, id e
# class. O required fica pelo caminho e o input chega ao navegador sem ele.
#
# O servidor continua exigindo o campo (validate_value_required, pelo ramo
# STUDENT_FIELD). Entao o navegador deixa submeter em branco, o servidor recusa,
# o formulario volta renderizado -- e aos olhos do candidato nada aconteceu. E o
# mesmo sintoma silencioso do campo de arquivo obrigatorio, por outro caminho.
RSpec.describe "Admissions required student field", type: :request do
  def processo_com(simple_url, campo)
    template = FactoryBot.create(:form_template, name: "Inscrição")
    FactoryBot.create(:form_field, form_template: template, **campo)
    FactoryBot.create(
      :admission_process, name: "Mestrado 2026.2",
      simple_url:, form_template: template,
      start_date: Date.today - 10.days, end_date: Date.today + 10.days,
      edit_date: Date.today + 20.days
    )
  end

  # Um campo por processo: assim o input do campo e o unico cujo name termina em
  # [value], e a medida nao depende da ordem em que o template os monta.
  def input_do(processo)
    get new_admission_apply_path(admission_id: processo.simple_id)
    Nokogiri::HTML(response.body).css("input").find do |input|
      input["name"].to_s.end_with?("[value]")
    end
  end

  def processo_local_de_expedicao
    processo_com("mestrado-local-expedicao", {
      name: "Local de expedição",
      field_type: Admissions::FormField::STUDENT_FIELD,
      configuration: { field: "identity_issuing_place", required: true }.to_json
    })
  end

  # Controle. Sem ele, "o input nao tem required" passaria tambem se o required
  # tivesse sumido de todo campo do formulario, ou se o seletor estivesse
  # pegando o input errado.
  it "marks a plain required field as required" do
    processo = processo_com("mestrado-texto", {
      name: "Naturalidade", field_type: Admissions::FormField::STRING,
      configuration: { required: true }.to_json
    })

    expect(input_do(processo)["required"]).to be_present
  end

  it "renders the issuing place field" do
    expect(input_do(processo_local_de_expedicao)).to be_present
  end

  it "marks the issuing place field as required" do
    expect(input_do(processo_local_de_expedicao)["required"]).to be_present
  end

  # A obrigatoriedade no servidor e o que segura o dado; o required da tela so
  # avisa antes. Este exemplo fixa esse lado para que a correcao do HTML nao
  # seja confundida com autorizacao para afrouxar a validacao.
  it "still refuses a blank issuing place on the server" do
    processo = processo_local_de_expedicao
    campo = processo.form_template.fields.first

    expect {
      submete(processo, campo, "")
    }.not_to change { Admissions::AdmissionApplication.count }
  end

  # O prejuizo relatado na #604: recusada a submissao, os anexos que o candidato
  # ja tinha escolhido voltam vazios e precisam ser reenviados um a um.
  #
  # Este exemplo passa dos dois lados da correcao, de proposito. Repassar o
  # required apenas evita que se chegue ate aqui por um campo em branco --
  # qualquer outro erro de validacao continua descartando os anexos. E o que a
  # #604 ainda pede, e o que este exemplo mantem a vista.
  it "discards an already uploaded file when the submission is refused" do
    processo = processo_local_de_expedicao
    template = processo.form_template
    campo = template.fields.first
    campo_arquivo = FactoryBot.create(
      :form_field, form_template: template, name: "Comprovante",
      field_type: Admissions::FormField::FILE
    )

    submete(processo, campo, "", arquivo: campo_arquivo)

    expect(response.body).to include(
      I18n.t("admissions.apply.edit.upload_notice")
    )
    expect(response.body).not_to include("zz_comprovante")
  end

  def submete(processo, campo, valor, arquivo: nil)
    campos = { "0" => { form_field_id: campo.id, value: valor } }
    if arquivo
      caminho = File.join(Dir.mktmpdir, "zz_comprovante.png")
      FileUtils.cp(Rails.root.join("spec", "fixtures", "user.png"), caminho)
      campos["1"] = {
        form_field_id: arquivo.id,
        file: Rack::Test::UploadedFile.new(caminho, "image/png")
      }
    end
    post admission_apply_index_path(admission_id: processo.simple_id), params: {
      commit: "Enviar inscrição",
      record: {
        name: "ZZ-TESTE Candidato", email: "zzteste@ic.uff.br",
        filled_form_attributes: {
          form_template_id: processo.form_template.id,
          enable_submission: "1",
          fields_attributes: campos
        }
      }
    }
  end
end
