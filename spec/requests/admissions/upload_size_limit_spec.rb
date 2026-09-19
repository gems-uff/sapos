# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O limite de upload virou configuravel pela variavel max_upload_size_mb, mas so
# no servidor. Os campos de arquivo do formulario de inscricao registram em
# customFormValidations uma checagem propria, com 15 MB escrito no proprio ERB, e
# essa checagem roda antes do envio: o edit.html.erb percorre
# customFormValidations no clique do submit e chama preventDefault na primeira
# que devolve false. Com a variavel configurada acima de 15, o navegador recusa o
# arquivo que o servidor aceitaria, e a mensagem ainda fala em 15MB -- a
# configuracao nao tem efeito no caminho por onde o candidato passa.
RSpec.describe "Admissions upload size limit", type: :request do
  def processo_com(simple_url, field_type:, configuration:)
    template = FactoryBot.create(:form_template, name: "Inscrição")
    FactoryBot.create(
      :form_field, form_template: template, name: "Currículo",
      field_type:, configuration: configuration.to_json
    )
    FactoryBot.create(
      :admission_process, name: "Mestrado 2026.2",
      simple_url:, form_template: template,
      start_date: Date.today - 10.days, end_date: Date.today + 10.days,
      edit_date: Date.today + 20.days
    )
  end

  def pagina_de(processo)
    get new_admission_apply_path(admission_id: processo.simple_id)
    response.body
  end

  it "uses the configured limit in the file field browser check" do
    CustomVariable.create!(variable: :max_upload_size_mb, value: "20")
    processo = processo_com(
      "mestrado-arquivo-configurado",
      field_type: Admissions::FormField::FILE, configuration: {}
    )

    corpo = pagina_de(processo)

    expect(corpo).to include("20 * 1024 * 1024")
    expect(corpo).not_to include("15 * 1024 * 1024")
  end

  it "uses the configured limit in the student photo browser check" do
    CustomVariable.create!(variable: :max_upload_size_mb, value: "20")
    processo = processo_com(
      "mestrado-foto-configurada",
      field_type: Admissions::FormField::STUDENT_FIELD,
      configuration: { field: "photo" }
    )

    corpo = pagina_de(processo)

    expect(corpo).to include("20 * 1024 * 1024")
    expect(corpo).not_to include("15 * 1024 * 1024")
  end

  # Controle: sem a variavel o limite do navegador continua sendo o padrao.
  # Sem ele, apagar a checagem do ERB deixaria os dois exemplos acima verdes.
  it "keeps the default limit in the browser when nothing is configured" do
    processo = processo_com(
      "mestrado-arquivo-padrao",
      field_type: Admissions::FormField::FILE, configuration: {}
    )

    corpo = pagina_de(processo)

    expect(corpo).to include("15 * 1024 * 1024")
  end
end
