# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O formulario de nova configuracao de relatorio do processo seletivo nunca era
# aberto (#720): o do_new do controller chama init_default, que ja traz os sete
# grupos padrao montados no subform, sem gravar nada.
RSpec.describe "Nova configuracao de relatorio de admissao", type: :request do
  before(:each) do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm.report.config@ic.uff.br", "Adm"
    )
  end

  it "abre com os grupos padrao pre-preenchidos e nada gravado" do
    expect do
      get new_admission_report_config_path
    end.not_to change { Admissions::AdmissionReportGroup.count }

    expect(response).to have_http_status(:ok)
    html = Nokogiri::HTML(response.body)
    modos = html.css("select[name$='[mode]'] option[selected]").map(&:text)
    expect(modos).to eq([
      Admissions::AdmissionReportGroup::MAIN,
      Admissions::AdmissionReportGroup::MAIN_LETTER,
      Admissions::AdmissionReportGroup::CONSOLIDATION,
      Admissions::AdmissionReportGroup::RANKING,
      Admissions::AdmissionReportGroup::PHASE_REVERSE,
      Admissions::AdmissionReportGroup::FIELD,
      Admissions::AdmissionReportGroup::LETTER,
    ])
    tabular = html.at_css("select[name='record[group_column_tabular]'] option[selected]")
    expect(tabular.text).to eq(Admissions::AdmissionReportConfig::MERGE)
  end
end
