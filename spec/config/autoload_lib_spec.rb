# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O config/application.rb entrega lib/ ao Zeitwerk com `autoload_lib`. Estes
# exemplos fixam as PREMISSAS que a chamada assume sobre o conteudo de lib/ --
# nao o comportamento do Rails, que a suite do Rails ja cobre.
RSpec.describe "premissas do autoload_lib" do
  let(:lib) { Rails.root.join("lib") }
  let(:loader) { Rails.autoloaders.main }

  # O Rails decide o eager load consultando um Set de Strings. Um Pathname no
  # eager_load_paths nunca casa: e o no-op silencioso que a linha antiga tinha,
  # e que deixava lib/ fora do eager load ate em producao.
  it "lib/ esta no eager_load_paths como String, que e o que o Rails compara" do
    expect(Rails.application.config.eager_load_paths).to include(lib.to_s)
  end

  # Em producao lib/ inteiro carrega no boot. `force: true` ignora as exclusoes
  # de eager load e reproduz isso aqui, onde eager_load e desligado fora do CI:
  # arquivo Ruby fora da convencao (constante com outro nome, codigo solto no
  # topo) quebra aqui antes de quebrar o boot de producao.
  it "lib/ inteiro sobrevive ao eager load" do
    expect { loader.eager_load(force: true) }.not_to raise_error
  end

  # Cada .rb em lib/ deve ter uma constante esperada pelo Zeitwerk. O `ignore`
  # existe para .rake e assets, nao para esconder codigo: um .rb dentro de pasta
  # ignorada nao aparece em all_expected_cpaths e falha aqui, com nome.
  it "todo .rb de lib/ e gerido pelo Zeitwerk, inclusive nas pastas ignoradas" do
    geridos = loader.all_expected_cpaths.keys
    ruby_em_lib = Dir[lib.join("**", "*.rb").to_s]

    expect(ruby_em_lib).not_to be_empty
    expect(ruby_em_lib - geridos).to be_empty
  end
end
