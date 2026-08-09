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
end
