# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A conversao do valor de parametro de consulta para os tipos de data, hora,
# decimal e literal nao tinha exemplo (#720). E o que vai para o SQL das
# consultas, notificacoes e declaracoes. A lista tem reproducao propria (#724).
RSpec.describe QueryParam, "#parsed_value", type: :model do
  def valor(tipo, texto)
    QueryParam.new(name: "p", value_type: tipo, default_value: texto).parsed_value
  end

  it "converte data escrita em texto" do
    expect(valor(QueryParam::VALUE_DATE, "2026-03-10")).to eq(Date.new(2026, 3, 10))
  end

  it "reduz a data o instante com fuso" do
    param = QueryParam.new(name: "p", value_type: QueryParam::VALUE_DATE)
    param.simulation_value = Time.zone.local(2026, 3, 10, 23, 0)

    expect(param.parsed_value).to eq(Date.new(2026, 3, 10))
  end

  it "converte data e hora escrita em texto" do
    expect(valor(QueryParam::VALUE_DATETIME, "2026-03-10 14:30")).to eq(DateTime.new(2026, 3, 10, 14, 30))
  end

  it "converte instante com fuso em DateTime" do
    param = QueryParam.new(name: "p", value_type: QueryParam::VALUE_DATETIME)
    param.simulation_value = Time.zone.local(2026, 3, 10, 14, 30)

    expect(param.parsed_value).to be_a(DateTime)
    expect(param.parsed_value).to eq(Time.zone.local(2026, 3, 10, 14, 30).to_datetime)
  end

  it "converte hora no dia corrente" do
    hora = valor(QueryParam::VALUE_TIME, "14:30")

    expect([hora.hour, hora.min]).to eq([14, 30])
    expect(hora.to_date).to eq(Date.current)
  end

  it "converte decimal" do
    expect(valor(QueryParam::VALUE_FLOAT, "7.5")).to eq(7.5)
  end

  it "mantem o literal como foi escrito" do
    expect(valor(QueryParam::VALUE_LITERAL, "status = 'ativo'")).to eq("status = 'ativo'")
  end

  it "devolve o valor vazio sem converter" do
    expect(valor(QueryParam::VALUE_DATE, "")).to eq("")
  end
end
