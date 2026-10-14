# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O campo de tipo HTML do template de inscrição é um bloco livre, escrito por
# coordenação ou administrador, e renderizado para o candidato -- que é anônimo.
# Ele tem de sair sanitizado: formatação, listas e links passam; script,
# manipuladores on* e URL javascript: caem. Sem isso, uma conta interna
# comprometida vira XSS armazenado contra todo candidato do processo.
RSpec.describe "Admissions: campo HTML sanitizado no formulário público", type: :request do
  before(:each) do
    @template = FactoryBot.create(:form_template, name: "Inscrição")
    FactoryBot.create(
      :form_field, form_template: @template, name: "Instruções",
      field_type: Admissions::FormField::HTML,
      configuration: {
        html: '<p class="aviso">Leia <a href="https://uff.br/edital" title="Edital">o edital</a> ' \
              "e <strong>anexe</strong> os documentos.</p>" \
              "<ul><li>Item</li></ul>" \
              "<table><tr><td>Prazo</td></tr></table>" \
              '<script>alert("xss")</script>' \
              "<style>p{color:#bada55}</style>" \
              '<iframe src="https://example.invalid"></iframe>' \
              '<img src="x" onerror="alert(1)">' \
              '<a href="javascript:alert(2)">clique</a>'
      }.to_json
    )
    @process = FactoryBot.create(
      :admission_process, name: "Mestrado 2026.2",
      simple_url: "mestrado-html", form_template: @template,
      start_date: Date.today - 10.days, end_date: Date.today + 10.days,
      edit_date: Date.today + 20.days
    )
  end

  it "mantém formatação, links e tabela e remove script, style, iframe, manipuladores e javascript:" do
    get new_admission_apply_path(admission_id: @process.simple_id)

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include('<p class="aviso">Leia <a href="https://uff.br/edital" title="Edital">o edital</a>')
    expect(body).to include("<strong>anexe</strong>")
    expect(body).to include("<ul><li>Item</li></ul>")
    expect(body).to include("<td>Prazo</td>")
    # A página tem <script> próprios; o que não pode aparecer é o CONTEÚDO dos
    # elementos podados. É por isso que o scrubber é o de poda: a lista padrão
    # do sanitize tiraria a tag e deixaria alert("xss") como texto na tela.
    expect(body).not_to include("xss")
    expect(body).not_to include("bada55")
    expect(body).not_to include("example.invalid")
    expect(body).not_to include("onerror")
    expect(body).not_to include("javascript:alert")
  end
end
