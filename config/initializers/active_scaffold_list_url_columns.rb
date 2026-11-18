# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# ActiveScaffold::Actions::Core#conditions_from_params transforma em filtro da
# lista qualquer parametro da URL com nome de coluna do banco do modelo:
# igualdade (/x?coluna=valor), faixa em numero e data (/x?coluna=a..b) e
# diferenca (/x?coluna!=valor). Quem lista um modelo confirma assim, pelo que
# a lista devolve, o valor de coluna que nenhuma tela lhe mostra. O filtro vale
# para tudo o que parte das condicoes da lista: a propria lista, o PDF e o lote
# montados sobre ela.
#
# Aqui a lista so filtra pela URL a coluna que o controller declara em
# active_scaffold_list_url_columns. Quem usa o filtro e a tela que abre a
# lista de outro scaffold com a coluna na URL (a situacao do processo
# seletivo abre a lista de candidaturas por processo e fase); ao acrescentar
# uma, declare a coluna no controller da lista. A busca da tela, o id, a
# lista aninhada e a lista embutida seguem outros caminhos e nao passam por
# aqui.
#
# Prepend no modulo, porque ele e incluido em cada controller pela chamada
# active_scaffold e ficaria na frente de um metodo do ApplicationController.
module ActiveScaffoldListUrlColumns
  protected
    def active_scaffold_list_url_columns
      []
    end

    # Igualdade, e so com valor simples: sem a faixa e sem a diferenca da gem,
    # e um parametro em forma de hash ou de lista e ignorado. O valor vazio
    # segue o que a gem faz: em coluna que aceita nulo, filtra pelo nulo (a
    # candidatura sem fase).
    def conditions_from_params
      @conditions_from_params ||= begin
        conditions = {}
        active_scaffold_list_url_columns.each do |name|
          column = active_scaffold_config._columns_hash[name.to_s]
          value = params[name]
          next unless column && value.is_a?(String)
          next if active_scaffold_constraints[name.to_sym]
          next if nested? && nested.param_name == name.to_sym

          empty = value == "" && (%i[string text].exclude?(column.type) || column.null)
          conditions[name.to_sym] =
            ActiveScaffold::Core.column_type_cast(empty ? column.default : value, column)
        end
        [conditions]
      end
    end
end

ActiveScaffold::Actions::Core.prepend(ActiveScaffoldListUrlColumns)
