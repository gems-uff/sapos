# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# A linha do tempo da bolsa marca a alocacao cancelada com a data de termino
# prevista no titulo do evento; a interpolacao termina em "}}", e o titulo sai
# com uma chave sobrando.
RSpec.describe ScholarshipsHelper, "linha do tempo de alocacao cancelada", type: :helper do
  before(:each) do
    bolsa = FactoryBot.create(:scholarship,
      start_date: Date.new(2025, 1, 1), end_date: Date.new(2027, 12, 31))
    @alocacao = FactoryBot.create(:scholarship_duration, scholarship: bolsa,
      start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 12, 1))
    @alocacao.update_column(:cancel_date, Date.new(2026, 6, 1))
    @saida = helper.scholarship_timeline_show_column(@alocacao.scholarship.reload, nil)
    @termino = helper.monthyear2(@alocacao.end_date)
  end

  # Controle: a alocacao aparece como cancelada, com o termino previsto.
  it "mostra o termino previsto da alocacao cancelada" do
    expect(@saida).to include(@termino)
  end

  it "fecha o titulo sem chave sobrando", pending: "issue #728" do
    expect(@saida).not_to include("#{@termino}}")
  end
end
