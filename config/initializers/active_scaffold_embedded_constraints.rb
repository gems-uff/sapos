# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# A lista embutida do active_scaffold (render active_scaffold: ...,
# constraints:) leva as restricoes na URL que o navegador pede para preencher a
# lista (embedded[constraints]), e ActiveScaffold::Constraints as le de la sem
# conferir de onde vieram. Elas filtram a lista por qualquer coluna do banco do
# modelo e, no registro novo (new, create, render_field, edit_associated),
# viram atribuicao por setter de qualquer atributo, fora das colunas do
# formulario: data de criacao, chave de associacao, e a colecao de versoes do
# PaperTrail, que puxa para o registro novo a versao de outro registro.
#
# O SAPOS nao embute lista com constraints, entao nenhuma restricao da
# requisicao vale. O scaffold aninhado nao passa por aqui: ele restringe pelo
# NestedInfo, montado no servidor.
#
# Prepend no modulo, nao override no ApplicationController: Constraints e
# incluido em cada controller pela chamada active_scaffold e ficaria na frente
# de um metodo herdado.
module ActiveScaffoldEmbeddedConstraints
  def active_scaffold_constraints
    @active_scaffold_constraints ||= {}
  end
end

ActiveScaffold::Constraints.prepend(ActiveScaffoldEmbeddedConstraints)
