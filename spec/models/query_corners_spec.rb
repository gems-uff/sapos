# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Dois caminhos de Query sem cobertura (#720): a execucao com valor de
# parametro invalido, que devolve o resultado vazio com os erros em vez de ir
# ao banco, e o toque nas notificacoes quando a lista de parametros muda (o
# next_execution delas depende dos parametros).
RSpec.describe Query, "cantos", type: :model do
  it "nao executa e devolve os parametros com erro quando o valor e invalido" do
    query = Query.create!(
      name: "Recentes", sql: "SELECT id FROM users WHERE created_at > :desde",
      params_attributes: [{ name: "desde", value_type: QueryParam::VALUE_DATE, default_value: "2026-01-01" }]
    )

    resultado = query.execute(desde: "abc")

    expect(resultado).to include(columns: [], rows: [], query: "")
    expect(resultado[:errors].first.errors.details[:default_value]).to include(error: :invalid_date)
  end

  describe "parametros alterados numa consulta com notificacao" do
    before(:each) do
      @query = FactoryBot.create(:query, sql: "SELECT id FROM users")
      @notificacao = FactoryBot.create(:notification, query: @query)
      @notificacao.update_column(:updated_at, 2.days.ago)
    end

    it "toca a notificacao quando um parametro entra" do
      @query.update!(params_attributes: [{ name: "novo", value_type: QueryParam::VALUE_STRING, default_value: "x" }])

      expect(@notificacao.reload.updated_at).to be > 1.minute.ago
    end

    it "nao toca a notificacao quando so o nome da consulta muda" do
      @query.update!(name: "Outro nome")

      expect(@notificacao.reload.updated_at).to be < 1.day.ago
    end
  end
end
