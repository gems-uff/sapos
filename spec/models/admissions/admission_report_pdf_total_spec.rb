# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Relatorio do edital: o "Total de Inscritos" do titulo do PDF diante da
# condicao de selecao e dos candidatos parciais (issue #765).
RSpec.describe Admissions::AdmissionReportConfig, "total do PDF do relatorio do edital", type: :model do
  def report_with(groups, **attrs)
    report = Admissions::AdmissionReportConfig.new(
      { group_column_tabular: Admissions::AdmissionReportConfig::MERGE, hide_empty_sections: false }.merge(attrs)
    )
    groups.each_with_index do |(mode, operation, columns), index|
      group = report.groups.build(order: index + 1, mode: mode, in_simple: true,
        operation: operation || Admissions::AdmissionReportGroup::EXCLUDE,
        pdf_format: Admissions::AdmissionReportGroup::TABLE)
      (columns || []).each_with_index { |name, i| group.columns.build(name: name, order: i + 1) }
    end
    report
  end

  def headers(report, process)
    report.prepare_table(process)[:header].map { |column| column[:header] }
  end

  describe "total do titulo do PDF" do
    before(:each) do
      template = create_admission_template("Insc Total", { "nota" => Admissions::FormField::NUMBER })
      @process = create_closed_admission_process(template, simple_url: "relatorio-total")
      create_application(@process, name: "Ana", fields: { "nota" => "8" })
      create_application(@process, name: "Bia", fields: { "nota" => "3" })
      create_application(@process, name: "Duda", filled: false, fields: { "nota" => "9" })
    end

    def total_e_linhas(report)
      contexto = Class.new { include ApplicationHelper; include Admissions::AdmissionProcessesPdfHelper }.new
      total = contexto.admission_process_pdf_title(@process).flatten.join[/(\d+)\s*<\/b>\z/, 1].to_i
      [total, report.prepare_table(@process)[:applications].size]
    end

    it "controle: sem condicao, o total e o numero de linhas" do
      total, linhas = total_e_linhas(report_with([[Admissions::AdmissionReportGroup::MAIN]]))
      expect(total).to eq(linhas)
    end

    it "com condicao de selecao, o total e o numero de linhas", pending: "issue #765" do
      total, linhas = total_e_linhas(report_with([[Admissions::AdmissionReportGroup::MAIN]],
        form_condition: field_condition("nota", Admissions::FormCondition::GE, "5")))
      expect(total).to eq(linhas)
    end

    it "mostrando candidatos parciais, o total e o numero de linhas", pending: "issue #765" do
      total, linhas = total_e_linhas(report_with([[Admissions::AdmissionReportGroup::MAIN]], show_partial_candidates: true))
      expect(total).to eq(linhas)
    end
  end
end
