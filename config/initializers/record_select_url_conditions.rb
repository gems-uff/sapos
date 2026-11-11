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
# Nenhum seletor do SAPOS usa esse filtro: os que restringem registros o fazem
# em record_select_conditions_from_controller, e a busca digitada passa por
# record_select_conditions_from_search, sobre as colunas de search_on. Aqui o
# parametro da URL deixa de filtrar.
#
# Prepend no modulo, porque ele e incluido em cada controller pela chamada
# record_select e ficaria na frente de um metodo do ApplicationController.
module RecordSelectUrlConditions
  protected
    def record_select_conditions_from_params
      []
    end
end

RecordSelect::Conditions.prepend(RecordSelectUrlConditions)
