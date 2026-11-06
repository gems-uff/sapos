# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe ProfessorsHelper, type: :helper do
  # Esta tabela monta HTML por interpolacao de string, entao cada valor cai num
  # to_s implicito -- era o que o monkey-patch global de Date#to_s cobria (#625).
  # A regiao estava sem cobertura nenhuma quando o patch saiu.
  describe "professor_institutions_show_column" do
    let(:professor) { FactoryBot.create(:professor) }

    it "renders a dash when the professor has no affiliation" do
      expect(helper.professor_institutions_show_column(professor, {})).to eq "-"
    end

    # affiliations.start_date e end_date sao colunas datetime, nao date: e o
    # caso em que o I18n escolheria o formato longo por extenso se date_br nao
    # convertesse para Date antes.
    it "formats the affiliation period in the brazilian format" do
      FactoryBot.create(
        :affiliation, professor: professor,
        start_date: Time.zone.local(2018, 3, 1, 14, 30),
        end_date: Time.zone.local(2021, 12, 31, 9, 0)
      )
      html = helper.professor_institutions_show_column(professor, {})

      expect(html).to include("<td>01/03/2018</td>")
      expect(html).to include("<td>31/12/2021</td>")
    end

    it "keeps the period out of the long format of time" do
      FactoryBot.create(
        :affiliation, professor: professor,
        start_date: Time.zone.local(2018, 3, 1, 14, 30), end_date: nil
      )
      html = helper.professor_institutions_show_column(professor, {})

      expect(html).not_to include("Março")
      expect(html).not_to include("14:30")
    end

    it "falls back to the blank text on an open affiliation" do
      FactoryBot.create(
        :affiliation, professor: professor,
        start_date: Time.zone.local(2018, 3, 1), end_date: nil
      )
      html = helper.professor_institutions_show_column(professor, {})

      expect(html).to include("<td>#{I18n.t('rescue_blank_text')}</td>")
    end

    # O modelo so aceita uma afiliacao por data de inicio e uma por data de fim
    # no mesmo professor, entao os periodos abaixo nao se repetem.
    it "renders one row per affiliation" do
      FactoryBot.create(
        :affiliation, professor: professor,
        start_date: Time.zone.local(2014, 2, 1),
        end_date: Time.zone.local(2017, 12, 31)
      )
      FactoryBot.create(
        :affiliation, professor: professor,
        start_date: Time.zone.local(2018, 3, 1),
        end_date: Time.zone.local(2021, 12, 31)
      )
      html = helper.professor_institutions_show_column(professor, {})

      expect(html.scan("<tr class=").size).to eq 2
      expect(html).to include("even-record")
    end
  end

  # O :advisement_authorizations padrão usa to_label (só o nome do nível), sem
  # período: com mais de três linhas o associated_limit pode esconder
  # justamente a vigente (achado C1 da revisão do PR #690).
  describe "professor_advisement_authorizations_show_column" do
    let(:professor) { FactoryBot.create(:professor) }

    it "renders a dash when the professor has no accreditation" do
      expect(helper.professor_advisement_authorizations_show_column(professor, {})).to eq "-"
    end

    it "shows the level and the period" do
      level = FactoryBot.create(:level, name: "Doutorado")
      FactoryBot.create(
        :advisement_authorization, professor: professor, level: level,
        start_date: Date.new(2018, 3, 1), end_date: Date.new(2021, 12, 31)
      )
      html = helper.professor_advisement_authorizations_show_column(professor, {})

      expect(html).to include("<td>Doutorado</td>")
      expect(html).to include("<td>01/03/2018</td>")
      expect(html).to include("<td>31/12/2021</td>")
    end

    it "falls back to the blank text on an open accreditation" do
      FactoryBot.create(:advisement_authorization, professor: professor, end_date: nil)
      html = helper.professor_advisement_authorizations_show_column(professor, {})

      expect(html).to include("<td>#{I18n.t('rescue_blank_text')}</td>")
    end

    it "orders the rows by start_date, not by insertion order" do
      level = FactoryBot.create(:level)
      recente = FactoryBot.create(
        :advisement_authorization, professor: professor, level: level,
        start_date: Date.new(2022, 1, 1), end_date: nil
      )
      antigo = FactoryBot.create(
        :advisement_authorization, professor: professor, level: FactoryBot.create(:level),
        start_date: Date.new(2015, 1, 1), end_date: Date.new(2021, 12, 31)
      )
      html = helper.professor_advisement_authorizations_show_column(professor, {})

      expect(html.index(antigo.level.name)).to be < html.index(recente.level.name)
    end

    # O nome do nível entra na tabela por interpolação de string, sem o
    # auto-escape das views: sem h(), um nível com `<` quebraria a tabela.
    it "escapes the level name" do
      level = FactoryBot.create(:level, name: "<script>")
      FactoryBot.create(:advisement_authorization, professor: professor, level: level)
      html = helper.professor_advisement_authorizations_show_column(professor, {})

      expect(html).to include("&lt;script&gt;")
      expect(html).not_to include("<script>")
    end
  end

  # As duas tabelas montadas a mao neste helper abriam <tboby>, erro de
  # digitacao. O navegador expulsava o elemento desconhecido e criava um <tbody>
  # sozinho, entao a tela nunca quebrou -- mas o HTML era invalido e a classe
  # que marca o corpo das tabelas de show se perdia junto.
  describe "as tabelas montadas a mao" do
    let(:professor) { FactoryBot.create(:professor) }

    it "serves a valid tbody in the institutions table" do
      FactoryBot.create(
        :affiliation, professor: professor,
        start_date: Time.zone.local(2018, 3, 1), end_date: nil
      )
      html = helper.professor_institutions_show_column(professor, {})

      expect(html).to include("<tbody class=\"records\">")
      expect(html).not_to include("tboby")
    end

    it "renders a dash when the professor advises nobody" do
      expect(helper.professor_advisements_with_points_show_column(professor, {}))
        .to eq "-"
    end
  end
end
