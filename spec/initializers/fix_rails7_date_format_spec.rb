# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# O initializer sobrescreve Date#to_s para que a interpolacao de uma data use o
# formato :default (%d/%m/%Y), comportamento que o Rails 7.0 removeu de proposito.
# O ramo de fallback dependia de to_default_s, um metodo interno do Rails que o
# 7.2 removeu -- e que quebrou sem que nada acusasse, porque nenhum spec o
# exercitava.
RSpec.describe "Date#to_s com formato padrao" do
  let(:date) { Date.new(2026, 7, 22) }

  it "usa o formato :default quando chamado sem argumento" do
    expect(date.to_s).to eq "22/07/2026"
  end

  it "usa o formato :default quando ele e pedido explicitamente" do
    expect(date.to_s(:default)).to eq "22/07/2026"
  end

  it "aceita outros formatos registrados em DATE_FORMATS" do
    expect(date.to_s(:iso8601)).to eq "2026-07-22"
  end

  it "cai no to_s original do Ruby quando o formato e desconhecido" do
    expect { date.to_s(:formato_que_nao_existe) }.not_to raise_error
    expect(date.to_s(:formato_que_nao_existe)).to eq "2026-07-22"
  end

  it "mantem to_default_s como o to_s original do Ruby" do
    expect(date.to_default_s).to eq "2026-07-22"
  end
end
