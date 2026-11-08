# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# A lista embutida do active_scaffold (render active_scaffold: ..., conditions:)
# leva as condicoes na URL que o navegador pede para preencher a lista
# (embedded[conditions]), e ActiveScaffold::Finder as aplica com where, sem
# conferir de onde vieram. Aqui nenhuma condicao da requisicao vale: as listas
# de pendencias mandam so o marcador "pendency", e a condicao e montada no
# servidor pelo pendency_condition do modelo, para o usuario corrente.
#
# Prepend no modulo, nao override no ApplicationController: o Finder e
# incluido em cada controller pela chamada active_scaffold e ficaria na frente
# de um metodo herdado.
module ActiveScaffoldEmbeddedConditions
  PENDENCY = "pendency"

  def active_scaffold_embedded_conditions
    return nil unless active_scaffold_embedded_params[:conditions] == PENDENCY
    model = active_scaffold_config.model
    model.pendency_condition(current_user) if model.respond_to?(:pendency_condition)
  end
end

ActiveScaffold::Finder.prepend(ActiveScaffoldEmbeddedConditions)
