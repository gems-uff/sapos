# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Relatorio configuravel do processo com colunas escolhidas (#720). A
# configuracao padrao nao tem coluna de ranking nem grupo com colunas, entao o
# formulario nunca montava os nomes dessas colunas, o PDF curto nunca caia na
# escala de larguras so com coluna fixa e o PDF completo nunca via campo de
# arquivo sem arquivo.
RSpec.describe "Admissions::AdmissionProcesses: relatorio com colunas escolhidas", type: :request do
  before(:each) do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm_colunas_relatorio@ic.uff.br", "Adm"
    )
    @template = create_admission_template("Inscricao", {
      "nota" => Admissions::FormField::NUMBER,
      "comprovante" => Admissions::FormField::FILE,
    })
    @process = create_closed_admission_process(@template, simple_url: "colunas-relatorio")
    @ana = create_application(@process, name: "Ana Colunas", fields: { "nota" => "9" })
  end

  # Configuracao guardada na sessao pelo custom_report_generate, no formato do
  # subform do active_scaffold. Os grupos enviados substituem os do padrao.
  def gera_relatorio(groups:, ranking_columns: {})
    post custom_report_generate_admission_processes_path, params: {
      record: {
        name: "Relatorio escolhido",
        group_column_tabular: Admissions::AdmissionReportConfig::COLUMN,
        groups: groups,
        ranking_columns: ranking_columns,
      },
    }
    expect(flash[:info]).to eq("Relatório configurado")
  end

  def grupo(order, mode, operation, columns, in_simple: "1")
    {
      order: order.to_s, mode: mode, operation: operation, in_simple: in_simple,
      pdf_format: Admissions::AdmissionReportGroup::LIST,
      columns: columns.each_with_index.to_h { |name, i| ["c#{i}", { name: name, order: i.to_s }] },
    }
  end

  it "o formulario mostra a coluna de ranking e a coluna do grupo guardadas na sessao" do
    gera_relatorio(
      groups: { "g1" => grupo(1, Admissions::AdmissionReportGroup::FIELD,
        Admissions::AdmissionReportGroup::INCLUDE, ["nota"]) },
      ranking_columns: { "r1" => { name: "nota", order: Admissions::RankingColumn::DESC } }
    )

    get custom_report_admission_processes_path

    expect(response).to have_http_status(:ok)
    html = Nokogiri::HTML(response.body)
    nomes = html.css("input.text-input[value='nota']").map { |input| input["name"] }
    expect(nomes).to include(a_string_matching(/\[ranking_columns\]\[\d+\]\[name\]\z/))
    expect(nomes).to include(a_string_matching(/\[columns\]\[\d+\]\[name\]\z/))
  end

  # So "token" tem largura fixa; com o grupo principal restrito a ela, a soma
  # das larguras (130) nao fecha os 560 do PDF e as colunas sao escaladas.
  it "o PDF curto so com a coluna de largura fixa sai com a coluna escolhida" do
    gera_relatorio(groups: {
      "g1" => grupo(1, Admissions::AdmissionReportGroup::MAIN,
        Admissions::AdmissionReportGroup::INCLUDE, ["token"]),
    })

    get short_pdf_admission_process_path(@process, format: :pdf)

    expect(response).to have_http_status(:ok)
    texto = pdf_representation(response.body)
    expect(texto).to include(@ana.token)
    expect(texto).not_to include("Ana Colunas")
  end

  it "o PDF completo deixa vazio o campo de arquivo nao enviado" do
    fill_fields(@ana.filled_form, { "comprovante" => nil })

    get complete_pdf_admission_process_path(@process, format: :pdf)

    expect(response).to have_http_status(:ok)
    texto = pdf_representation(response.body)
    expect(texto).to include("Ana Colunas")
    # A linha do campo sai so com o nome: nem nome de arquivo, nem link.
    expect(texto).to match(/^ *comprovante *$/)
  end
end
