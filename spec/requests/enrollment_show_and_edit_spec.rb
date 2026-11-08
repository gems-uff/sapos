# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A tela de detalhe da matricula e o formulario de edicao com nivel travado e
# area/linha de pesquisa indisponivel (#720). Nenhum exemplo fazia GET
# /enrollments/:id, entao os *_show_column de EnrollmentsHelper -- cada um com
# a sua tabela -- nunca rodavam; e o formulario so era aberto com matricula
# sem etapa concluida e com area disponivel.
RSpec.describe "Matricula: detalhe e edicao", type: :request do
  before(:each) do
    sign_in create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm_matricula_show@ic.uff.br", "Adm"
    )
    @level = FactoryBot.create(:level, name: "Nivel Detalhe")
    @enrollment = FactoryBot.create(
      :enrollment, enrollment_number: "M-DETALHE", level: @level,
      student: FactoryBot.create(:student, name: "Aluno Detalhe"),
      admission_date: Date.new(2021, 3, 1)
    )
  end

  # O show do active_scaffold poe cada coluna num <dd> com a classe
  # "<coluna>-view", que o helper preenche.
  def coluna(nome)
    Nokogiri::HTML(response.body).css("dd.#{nome}-view").first&.text&.squish
  end

  describe "detalhe" do
    it "mostra traco nas listas vazias" do
      get enrollment_path(@enrollment)

      expect(response).to have_http_status(:ok)
      expect(coluna("admission_date")).to eq("Março-2021")
      %w[
        dismissal advisements deferrals scholarship_durations enrollment_holds
        class_enrollments thesis_defense_committee_participations phase_due_dates
      ].each do |nome|
        expect(coluna(nome)).to eq("-"), "coluna #{nome}"
      end
    end

    it "mostra cada lista preenchida" do
      professor = FactoryBot.create(:professor, name: "Professora Detalhe")
      FactoryBot.create(:advisement_authorization, professor: professor, level: @level,
        start_date: Date.new(2020, 1, 1))
      FactoryBot.create(:advisement, enrollment: @enrollment, professor: professor)
      FactoryBot.create(:thesis_defense_committee_participation, enrollment: @enrollment,
        professor: FactoryBot.create(:professor, name: "Membro Banca Detalhe"))
      FactoryBot.create(:enrollment_hold, enrollment: @enrollment)
      FactoryBot.create(:scholarship_duration, enrollment: @enrollment,
        scholarship: FactoryBot.create(:scholarship, scholarship_number: "BOLSA-DETALHE"))
      curso = FactoryBot.create(:course, name: "Disciplina Detalhe")
      FactoryBot.create(:class_enrollment, enrollment: @enrollment,
        course_class: FactoryBot.create(:course_class, course: curso))
      fase = FactoryBot.create(:phase, name: "Etapa Detalhe")
      FactoryBot.create(:phase_duration, phase: fase, level: @level)
      FactoryBot.create(:deferral, enrollment: @enrollment,
        deferral_type: FactoryBot.create(:deferral_type, name: "Prorrogacao Detalhe", phase: fase))
      FactoryBot.create(:dismissal, enrollment: @enrollment, date: Date.new(2023, 7, 1),
        dismissal_reason: FactoryBot.create(:dismissal_reason, name: "Titulado Detalhe"))

      get enrollment_path(@enrollment)

      expect(response).to have_http_status(:ok)
      expect(coluna("dismissal")).to eq("Titulado Detalhe - Julho-2023")
      expect(coluna("advisements")).to include("Professora Detalhe")
      expect(coluna("deferrals")).to include("Prorrogacao Detalhe")
      expect(coluna("scholarship_durations")).to include("BOLSA-DETALHE")
      expect(coluna("enrollment_holds")).not_to eq("-")
      expect(coluna("class_enrollments")).to include("Disciplina Detalhe")
      expect(coluna("thesis_defense_committee_participations")).to include("Membro Banca Detalhe")
      expect(coluna("phase_due_dates")).to include("Etapa Detalhe")
    end

    it "lista os documentos que o administrador pode gerar" do
      get enrollment_path(@enrollment)

      links = Nokogiri::HTML(response.body).css("dd.documents-view a").map { |a| a["href"] }
      expect(links).to include(
        override_signature_grades_report_pdf_enrollment_path(
          id: @enrollment.id, signature_type: :qr_code, format: :pdf
        ),
        override_signature_transcript_pdf_enrollment_path(
          id: @enrollment.id, signature_type: :manual, format: :pdf
        )
      )
    end
  end

  describe "edicao" do
    def html
      Nokogiri::HTML(response.body)
    end

    # Com etapa concluida, desligamento ou prorrogacao, o nivel sai como texto
    # e nao como select.
    it "trava o nivel da matricula com etapa concluida" do
      fase = FactoryBot.create(:phase)
      FactoryBot.create(:phase_duration, phase: fase, level: @level)
      FactoryBot.create(:accomplishment, enrollment: @enrollment, phase: fase)

      get edit_enrollment_path(@enrollment)

      expect(response).to have_http_status(:ok)
      expect(html.css("select[name='record[level]']")).to be_empty
      nivel = html.xpath("//dl[dt/label[text()='Nível']]/dd").first
      expect(nivel.text.squish).to eq("Nivel Detalhe")
    end

    # Controle: sem etapa concluida o nivel e um select.
    it "deixa o nivel editavel na matricula sem etapa concluida" do
      get edit_enrollment_path(@enrollment)

      expect(html.css("select[name='record[level]']")).not_to be_empty
    end

    # A area e a linha marcadas indisponiveis depois de atribuidas continuam
    # no select da propria matricula, para nao sumirem ao salvar.
    it "mantem a area e a linha indisponiveis que a matricula ja usa" do
      area = FactoryBot.create(:research_area, name: "Area Retirada")
      linha = FactoryBot.create(:research_line, name: "Linha Retirada", research_area: area)
      outra = FactoryBot.create(:research_area, name: "Area Retirada Alheia", available: false)
      @enrollment.update!(research_area: area, research_line: linha)
      area.update!(available: false)
      linha.update!(available: false)

      get edit_enrollment_path(@enrollment)

      expect(response).to have_http_status(:ok)
      areas = html.css("select[name='record[research_area]'] option")
      expect(areas.find { |o| o.text == "Area Retirada" }["selected"]).to be_present
      expect(areas.map(&:text)).not_to include(outra.name)
      linhas = html.css("select[name='record[research_line]'] option")
      expect(linhas.find { |o| o.text == "Linha Retirada" }["selected"]).to be_present
    end
  end
end
