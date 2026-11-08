# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Cantos do relatorio do processo seletivo sem cobertura (#720): campo de
# arquivo opcional que o candidato deixou sem anexo, nas tres formas de linha
# (tela/PDF, planilha, HTML); o grupo de fase sem comite em ordem direta; e o
# grupo de consolidacao com a operacao incluir.
RSpec.describe Admissions::AdmissionReportConfig, "cantos da tabela", type: :model do
  before(:each) do
    @template = create_admission_template("Inscricao", {
      "nota" => Admissions::FormField::NUMBER,
      "anexo" => Admissions::FormField::FILE,
    })
    @process = create_closed_admission_process(@template, simple_url: "relatorio-cantos")
    @ana = create_application(@process, name: "Ana", fields: { "nota" => "8", "anexo" => "" })
  end

  def report_with(groups, **attrs)
    report = Admissions::AdmissionReportConfig.new(
      { group_column_tabular: Admissions::AdmissionReportConfig::MERGE, hide_empty_sections: false }.merge(attrs)
    )
    groups.each_with_index do |(mode, operation, columns), index|
      group = report.groups.build(
        order: index + 1, mode: mode, operation: operation || Admissions::AdmissionReportGroup::EXCLUDE,
        pdf_format: Admissions::AdmissionReportGroup::TABLE
      )
      (columns || []).each_with_index do |name, column_index|
        group.columns.build(name: name, order: column_index + 1)
      end
    end
    report
  end

  def headers(config)
    config[:header].map { |column| column[:header] }
  end

  def section_titles(config)
    config[:groups].flat_map { |group| group.sections.map { |section| section[:title] } }
  end

  def in_table(config, application)
    config[:applications].find { |candidate| candidate == application }
  end

  describe "campo de arquivo sem anexo" do
    before(:each) do
      @report = report_with([[Admissions::AdmissionReportGroup::FIELD]])
      @config = @report.prepare_table(@process)
      @config[:base_url] = "http://sapos.test"
      @linha = in_table(@config, @ana)
      @coluna = headers(@config).index("anexo")
    end

    it "tem a coluna do anexo no cabecalho" do
      expect(headers(@config)).to eq(["nota", "anexo"])
    end

    it "sai vazio na linha da tela e do PDF" do
      expect(@report.prepare_row(@config, @linha).map { |e| e[:value] }).to eq(["8", ""])
    end

    it "sai vazio na planilha, sem formula de link" do
      resultado = @report.prepare_excel_row(@config, @linha)

      expect(resultado[:row][@coluna]).to eq("")
      expect(resultado[:row][0]).to eq("8")
    end

    it "sai vazio no HTML, sem ancora" do
      linha = @report.prepare_html_row(@config, @linha)

      expect(linha[@coluna][:value]).to eq("")
    end
  end

  describe "grupo de fase sem comite, em ordem direta" do
    it "lista as fases na ordem do processo e omite as avaliacoes individuais" do
      fase1 = add_phase(
        @process, 1, name: "Analise",
        shared_form: create_admission_template("Ficha", { "obs" => Admissions::FormField::STRING }),
        member_form: create_admission_template("Parecer", { "parecer" => Admissions::FormField::STRING })
      )
      add_phase(
        @process, 2, name: "Entrevista",
        shared_form: create_admission_template("Ficha Entrevista", { "nota_entrevista" => Admissions::FormField::NUMBER })
      )
      avaliador = professor_user("relatorio-cantos-avaliador@ic.uff.br")
      add_committee(fase1, [avaliador])

      report = report_with([[Admissions::AdmissionReportGroup::PHASE_WITHOUT_COMMITTEE]])
      titulos = section_titles(report.prepare_table(@process))

      expect(titulos.first).to eq("Analise - #{Admissions::AdmissionPhaseResult::SHARED}")
      expect(titulos.last).to eq("Entrevista - #{Admissions::AdmissionPhaseResult::SHARED}")
      expect(titulos).not_to include("Analise - #{avaliador.name}")
    end
  end

  describe "grupo de consolidacao com operacao incluir" do
    it "traz so as colunas nomeadas, na ordem do grupo" do
      consolidacao = create_consolidation_template("Relatorio", {
        "dobro" => code_field("{{ fields.nota | times: 2 }}"),
        "triplo" => code_field("{{ fields.nota | times: 3 }}"),
        "quadruplo" => code_field("{{ fields.nota | times: 4 }}"),
      })
      report = report_with(
        [[Admissions::AdmissionReportGroup::CONSOLIDATION, Admissions::AdmissionReportGroup::INCLUDE, ["quadruplo", "dobro"]]],
        form_template: consolidacao
      )
      config = report.prepare_table(@process)

      expect(headers(config)).to eq(["quadruplo", "dobro"])
      expect(report.prepare_row(config, in_table(config, @ana)).map { |e| e[:value] }).to eq(["32", "16"])
    end
  end
end
