# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Historico e boletim de matricula com titulo e banca cadastrados, mas sem data
# de defesa: EnrollmentsPdfHelper#thesis_table troca a data pelo texto de "nao
# informado" e, ao listar a banca, chama .to_date nesse texto (Date::Error).
RSpec.describe "Historico e boletim com banca e sem data de defesa", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm_banca@ic.uff.br", "Adm")
    @matricula = FactoryBot.create(:enrollment, admission_date: Date.new(2020, 3, 1))
    @matricula.update!(thesis_title: "Tese Sem Data")
    FactoryBot.create(:thesis_defense_committee_participation, enrollment: @matricula)
  end

  # Controle: com a data, o mesmo cenario gera o PDF.
  it "gera o historico quando a data de defesa existe" do
    @matricula.update!(thesis_defense_date: Date.new(2022, 5, 10))

    get academic_transcript_pdf_enrollment_path(@matricula, format: :pdf)

    expect(response).to have_http_status(:ok)
  end

  it "gera o historico sem data de defesa", pending: "issue #732" do
    get academic_transcript_pdf_enrollment_path(@matricula, format: :pdf)

    expect(response).to have_http_status(:ok)
  end

  it "gera o boletim sem data de defesa", pending: "issue #732" do
    get grades_report_pdf_enrollment_path(@matricula, format: :pdf)

    expect(response).to have_http_status(:ok)
  end
end
