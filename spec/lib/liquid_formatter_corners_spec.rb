# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Dois cantos do Liquid sem cobertura (#720): o filtro de media/mediana com
# propriedade sobre item que nao e registro, e o `{{ variables }}` impresso
# inteiro, que todo template recebe.
RSpec.describe LiquidFormatter, "nos cantos" do
  def render(template, data = {})
    LiquidFormatter.new(data).format(template)
  end

  it "conta como zero o item que nao responde a [] ao tirar a media de uma propriedade" do
    expect(render("{{ n | avg: 'nota' }}", { "n" => [{ "nota" => 9 }, nil, 3.0] }))
      .to eq("3.0")
  end

  it "conta como zero o item que nao responde a [] ao tirar a mediana de uma propriedade" do
    expect(render("{{ n | median: 'nota' }}", { "n" => [{ "nota" => 8 }, nil, { "nota" => 4 }] }))
      .to eq("4.0")
  end

  it "imprime as variaveis disponiveis quando o template mostra variables inteiro" do
    saida = CodeEvaluator.evaluate_code("{{ variables }}", {}, "Liquid")

    expect(saida).to start_with("variables(")
    CustomVariable::VARIABLES.each_key do |nome|
      expect(saida).to include(nome)
    end
  end
end
