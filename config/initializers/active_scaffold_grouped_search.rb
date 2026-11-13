# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# A busca por campos do active_scaffold agrupa a lista pelo que a URL nomeia em
# search[active_scaffold_group], sem conferir: qualquer coluna do modelo, que a
# lista agrupada passa a imprimir, mostre-a alguma tela ou nao; e o nome que
# nao e coluna derruba a lista. A busca fica guardada na sessao, entao a lista
# segue derrubada ate o usuario limpar a busca ou sair.
#
# Aqui a lista so agrupa pelo que o scaffold oferece para agrupar
# (field_search.group_options), como a tela de busca da gem oferece. Nenhum
# scaffold do SAPOS configura agrupamento: o parametro e ignorado.
#
# Prepend no modulo, porque ele e incluido em cada controller pela chamada
# active_scaffold e ficaria na frente de um metodo do ApplicationController.
module ActiveScaffoldGroupedSearch
  protected
    def grouped_search?
      return false unless super

      requested = field_search_params["active_scaffold_group"]
      Array(active_scaffold_config.field_search.group_options).any? do |text, value|
        (value || text).to_s == requested
      end
    end
end

ActiveScaffold::Actions::FieldSearch::InstanceMethods.prepend(ActiveScaffoldGroupedSearch)
