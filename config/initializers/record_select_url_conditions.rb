# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# RecordSelect::Conditions#record_select_conditions_from_params transforma em
# filtro qualquer parametro da URL com nome de coluna do modelo, e coluna de
# texto entra por LIKE com o padrao que veio da URL: /x/browse?coluna=abc%25
# so lista quem tem a coluna comecando por "abc". Quem abre o seletor de um
# modelo confirma assim, um pedaco de cada vez, o valor de coluna que nenhuma
# tela lhe mostra.
#
# Aqui o seletor so filtra pela URL a coluna que o controller dele declara em
# record_select_url_columns. Quem usa o filtro e o formulario que abre o
# seletor com options[:params] na coluna (o tipo do modelo de formulario, nos
# formularios do processo seletivo); ao acrescentar um, declare a coluna no
# controller do seletor. A busca digitada segue por
# record_select_conditions_from_search, sobre as colunas de search_on.
#
# Prepend no modulo, porque ele e incluido em cada controller pela chamada
# record_select e ficaria na frente de um metodo do ApplicationController.
module RecordSelectUrlConditions
  protected
    def record_select_url_columns
      []
    end

    def record_select_conditions_from_params
      record_select_url_columns.filter_map do |name|
        column = record_select_config.model.columns_hash[name.to_s]
        next if column.nil? || !params.key?(name)

        record_select_condition_for_column(column, params[name])
      end
    end
end

RecordSelect::Conditions.prepend(RecordSelectUrlConditions)
