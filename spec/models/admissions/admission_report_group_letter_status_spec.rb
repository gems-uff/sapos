# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Relatorio do edital: a situacao da carta ("Preenchida") no grupo de cartas
# em modo Excluir e no relatorio padrao (issue #757).
RSpec.describe Admissions::AdmissionReportConfig, "situacao da carta no relatorio do edital", type: :model do
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

  describe "situacao da carta no grupo de cartas" do
    before(:each) do
      template = create_admission_template("Insc Carta", { "nota" => Admissions::FormField::NUMBER })
      carta = create_admission_template("Carta", { "parecer" => Admissions::FormField::STRING },
        template_type: Admissions::FormTemplate::RECOMMENDATION_LETTER)
      @process = create_closed_admission_process(template, simple_url: "relatorio-carta-situacao",
        letter_template: carta, min_letters: nil, max_letters: 2)
      inscricao = create_application(@process, name: "Ana")
      FactoryBot.create(:letter_request, admission_application: inscricao, name: "Rec", email: "rec@example.com",
        filled_form: FactoryBot.create(:filled_form, form_template: carta, is_filled: true))
      @situacao = Admissions::LetterRequest.record_i18n_attr("status")
    end

    it "controle: em modo Incluir a situacao vem quando pedida" do
      report = report_with([[Admissions::AdmissionReportGroup::LETTER, Admissions::AdmissionReportGroup::INCLUDE, ["status"]]])
      expect(headers(report, @process)).to eq([@situacao])
    end

    it "em modo Excluir sem exclusao, a situacao vem", pending: "issue #757" do
      expect(headers(report_with([[Admissions::AdmissionReportGroup::LETTER]]), @process)).to include(@situacao)
    end

    it "no relatorio padrao, a situacao vem", pending: "issue #757" do
      expect(headers(Admissions::AdmissionReportConfig.new.init_default, @process)).to include(@situacao)
    end
  end
end
