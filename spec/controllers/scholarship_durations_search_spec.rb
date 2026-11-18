# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Busca de alocacoes de bolsa: so o ramo "nao ativa" de bolsa e o periodo de
# suspensao completo estavam cobertos. Sem cobertura (#720): bolsa "ativa",
# suspensao "nao ativa" e o periodo de suspensao com so o ano inicial ou so o
# ano final.
RSpec.describe ScholarshipDurationsController do
  def alocacao(inicio, fim)
    FactoryBot.create(:scholarship_duration, start_date: inicio, end_date: fim,
      scholarship: FactoryBot.create(:scholarship, start_date: inicio, end_date: fim))
  end

  def busca(condicao)
    ScholarshipDuration.where(*condicao)
  end

  describe "bolsa ativa" do
    it "fica com a que termina depois de hoje e nao foi cancelada" do
      vigente = alocacao(1.month.ago.to_date, 1.month.from_now.to_date)
      cancelada = alocacao(1.month.ago.to_date, 1.month.from_now.to_date)
      cancelada.update_column(:cancel_date, 1.day.ago.to_date)
      encerrada = alocacao(3.months.ago.to_date, 1.month.ago.to_date)

      resultado = busca(described_class.condition_for_active_column(nil, "active", nil))

      expect(resultado).to include(vigente)
      expect(resultado).not_to include(cancelada, encerrada)
    end
  end

  describe "suspensao" do
    before(:each) do
      @suspensa_ativa = alocacao(Date.new(2020, 1, 1), Date.new(2022, 12, 31))
      FactoryBot.create(:scholarship_suspension, scholarship_duration: @suspensa_ativa,
        start_date: Date.new(2020, 3, 1), end_date: Date.new(2020, 8, 31), active: true)
      @suspensa_inativa = alocacao(Date.new(2020, 1, 1), Date.new(2022, 12, 31))
      FactoryBot.create(:scholarship_suspension, scholarship_duration: @suspensa_inativa,
        start_date: Date.new(2021, 3, 1), end_date: Date.new(2021, 8, 31), active: false)
    end

    def suspensao(start_year: "", end_year: "", active_suspension: "")
      described_class.condition_for_suspended_column(
        nil, { start_year:, start_month: "", end_year:, end_month: "", active_suspension: }, nil
      )
    end

    it "nao ativa: so as alocacoes sem suspensao ativa" do
      expect(busca(suspensao(active_suspension: "not_active"))).to contain_exactly(@suspensa_inativa)
    end

    it "so com ano inicial: suspensoes que terminam depois do inicio do ano" do
      expect(busca(suspensao(start_year: "2021"))).to contain_exactly(@suspensa_inativa)
    end

    it "so com ano final: suspensoes que comecam antes do inicio do ano" do
      expect(busca(suspensao(end_year: "2021"))).to contain_exactly(@suspensa_ativa)
    end
  end
end
