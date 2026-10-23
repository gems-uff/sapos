# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Partial em app/views/active_scaffold_overrides/ sombreia o de mesmo nome
# dentro do active_scaffold. Quando ele e copia do partial da gem com um
# acrescimo, o upgrade da gem cria um conflito que o git nao ve: os dois lados
# continuam corretos isolados, o texto nao se sobrepoe, e a copia parada passa a
# desfazer, calada, a parte do upgrade que mudou aquele arquivo.
#
# O invariante que sustenta a copia e "so acrescentamos linhas". Se ele valer,
# toda linha do partial da gem aparece na nossa, na mesma ordem. Uma linha que a
# gem mudou some dessa sequencia, e e ai que este teste falha -- no upgrade, que
# e quando ainda da para decidir.
RSpec.describe "overrides do active_scaffold", type: :lib do
  gem_views = Pathname.new(Gem.loaded_specs["active_scaffold"].gem_dir)
    .join("app", "views", "active_scaffold_overrides")

  Dir[Rails.root.join("app", "views", "active_scaffold_overrides", "*")].sort.each do |nosso|
    da_gem = gem_views.join(File.basename(nosso))
    next unless da_gem.exist?

    it "#{File.basename(nosso)} so acrescenta linhas ao partial da gem" do
      base = da_gem.readlines.map(&:rstrip)
      copia = File.readlines(nosso).map(&:rstrip)

      restante = copia.dup
      sumidas = base.reject do |linha|
        posicao = restante.index(linha)
        restante = restante[(posicao + 1)..] if posicao
        posicao
      end

      expect(sumidas).to be_empty, <<~MSG
        O partial da gem mudou e a copia em app/views/active_scaffold_overrides/
        ficou para tras. Linha(s) do #{da_gem} que nao aparecem mais em #{nosso}:

        #{sumidas.map { |l| "  #{l.inspect}" }.join("\n")}

        Ressincronize a copia com o partial da versao em uso, reaplicando as
        mudancas proprias do SAPOS.
      MSG
    end
  end
end
