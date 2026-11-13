# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Parametro de consulta do tipo lista: valores so com digitos deveriam virar
# inteiros e valores com ponto, decimais. Os dois ramos estao trocados.
RSpec.describe QueryParam, "valor do tipo lista", type: :model do
  def lista(valor)
    QueryParam.new(value_type: QueryParam::VALUE_LIST, default_value: valor).parsed_value
  end

  # Controle: texto continua texto, nos dois lados do conserto.
  it "mantem como texto a lista que tem letra" do
    expect(lista("a,b")).to eq(["a", "b"])
  end

  it "converte lista de inteiros em inteiros", pending: "issue #724" do
    expect(lista("1,2")).to eq([1, 2])
    expect(lista("1,2").first).to be_an(Integer)
  end

  it "converte lista de decimais sem truncar", pending: "issue #724" do
    expect(lista("1.5,2.7")).to eq([1.5, 2.7])
  end
end
