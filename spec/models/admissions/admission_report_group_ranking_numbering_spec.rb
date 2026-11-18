# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Relatorio do edital: o numero na frente do nome de coluna (N.campo) segue a
# ordem do edital nas fases, e nos rankings conta de tras para frente
# (issue #778).
RSpec.describe Admissions::AdmissionReportConfig, "numeracao das colunas do relatorio do edital", type: :model do
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

  describe "numeracao de fases e rankings" do
    before(:each) do
      template = create_admission_template("Insc Num", { "nota" => Admissions::FormField::NUMBER })
      @process = create_closed_admission_process(template, simple_url: "relatorio-numeracao")
      create_application(@process, name: "Ana", fields: { "nota" => "8" })
    end

    it "controle: nas fases, 1. e a primeira do edital" do
      add_phase(@process, 1, name: "Primeira", shared_form: create_admission_template("F1", { "obs1" => Admissions::FormField::STRING }))
      add_phase(@process, 2, name: "Segunda", shared_form: create_admission_template("F2", { "obs2" => Admissions::FormField::STRING }))
      report = report_with([[Admissions::AdmissionReportGroup::PHASE_WITHOUT_COMMITTEE,
        Admissions::AdmissionReportGroup::INCLUDE, ["1.obs1", "1.obs2"]]])
      expect(headers(report, @process)).to eq(["obs1"])
    end

    it "nos rankings, 1. e o primeiro do edital", pending: "issue #778" do
      primeiro = FactoryBot.create(:ranking_config, name: "RankA")
      segundo = FactoryBot.create(:ranking_config, name: "RankB")
      FactoryBot.create(:admission_process_ranking, admission_process: @process, ranking_config: primeiro, order: 1)
      FactoryBot.create(:admission_process_ranking, admission_process: @process, ranking_config: segundo, order: 2)
      posicao = Admissions::RankingConfig::POSITION
      report = report_with([[Admissions::AdmissionReportGroup::RANKING, Admissions::AdmissionReportGroup::INCLUDE, ["1.#{posicao}"]]])
      expect(headers(report, @process)).to eq(["#{posicao}/RankA"])
    end
  end
end
