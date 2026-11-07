# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Ramos do historico e do boletim que nenhum cenario alcancava (#720):
# disciplina sem nota, banca cadastrada sem data de defesa e sem desligamento,
# bolsa gravada sem datas e a assinatura por QR code, que guarda o documento
# como Report.
RSpec.describe "Ramos do historico e do boletim em PDF", type: :request do
  include_context "consulta somente-leitura na conexao do teste"

  before(:each) do
    @admin = create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm_pdf_ramos@ic.uff.br", "Adm"
    )
    sign_in @admin
    @level = FactoryBot.create(:level)
    @enrollment = FactoryBot.create(
      :enrollment, enrollment_number: "M-RAMOS", level: @level,
      student: FactoryBot.create(:student, name: "Aluna Ramos"),
      admission_date: Date.new(2020, 3, 1)
    )
  end

  def texto_do_pdf
    pdf_representation(response.body)
  end

  it "o historico mostra AP na disciplina cujo tipo nao tem nota" do
    tipo = FactoryBot.create(:course_type, name: "Atividade", has_score: false)
    curso = FactoryBot.create(:course, name: "Seminario Ramos", code: "SEMRAMOS", course_type: tipo)
    turma = FactoryBot.create(:course_class, course: curso, year: 2020, semester: 1)
    FactoryBot.create(
      :class_enrollment, course_class: turma, enrollment: @enrollment,
      situation: ClassEnrollment::APPROVED, grade: nil
    )

    get academic_transcript_pdf_enrollment_path(@enrollment, format: :pdf)

    expect(response).to have_http_status(:ok)
    expect(texto_do_pdf).to match(/SEMRAMOS.*Seminario Ramos.*\bAP\b/)
  end

  # Com a data da defesa preenchida. Sem ela o historico responde 500: a linha
  # da data troca a variavel pelo texto "Nao informado", que a lista da banca
  # depois tenta converter em data (Date::Error).
  it "o historico com banca e sem desligamento sai sem julgamento" do
    @enrollment.update!(thesis_title: "Tese dos Ramos", thesis_defense_date: Date.new(2022, 5, 10))
    FactoryBot.create(:thesis_defense_committee_participation, enrollment: @enrollment)

    get academic_transcript_pdf_enrollment_path(@enrollment, format: :pdf)

    expect(response).to have_http_status(:ok)
    texto = texto_do_pdf
    expect(texto).to include("Tese dos Ramos")
    expect(texto).to match(%r{DATA DA DEFESA: 10/05/2022\s+JULGAMENTO: --})
  end

  # O modelo exige as duas datas; so dado legado ou gravado sem validacao chega
  # aqui, e o boletim troca a data ausente por "-".
  it "o boletim mostra traco na bolsa gravada sem datas" do
    duracao = FactoryBot.create(:scholarship_duration, enrollment: @enrollment)
    duracao.update_columns(start_date: nil, end_date: nil)

    get grades_report_pdf_enrollment_path(@enrollment, format: :pdf)

    expect(response).to have_http_status(:ok)
    numero = duracao.scholarship.scholarship_number
    expect(texto_do_pdf).to match(/#{Regexp.escape(numero)}.* - +- +-/)
  end

  it "o historico assinado por QR code fica guardado como Report do usuario" do
    FactoryBot.create(
      :report_configuration, use_at_transcript: true, signature_type: :qr_code,
      expiration_in_months: 2, order: 1, x: 0, y: 0, scale: 1
    )

    expect do
      get academic_transcript_pdf_enrollment_path(@enrollment, format: :pdf)
    end.to change(Report, :count).by(1)

    expect(response).to have_http_status(:ok)
    report = Report.order(:id).last
    expect(report.user).to eq(@admin)
    expect(report.file_name).to include("Aluna Ramos")
    expect(report.expires_at).to eq(Date.current + 2.months)
    expect(report.identifier).to be_present
  end
end
