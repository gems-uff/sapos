# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# A edicao em linha do active_scaffold tem duas rotas em todo scaffold: GET
# render_field?update_column=<coluna>, que devolve o campo com o valor, e POST
# update_column, que grava. A gem as aceita para QUALQUER coluna do scaffold,
# esteja a edicao em linha ligada nela ou nao: basta o usuario poder alterar o
# registro. A gravacao acontece em do_update_column, antes do que o formulario
# de cada tela confere (before_update_save recebe o registro ja alterado), e a
# leitura devolve o valor cru, sem o helper de coluna da lista.
#
# Aqui as duas so valem para a coluna em que o scaffold ligou a edicao em
# linha (config.columns[:x].inplace_edit = true). O SAPOS nao a liga em
# nenhuma; quem ligar passa a responder por aquela coluna.
#
# Prepend nos modulos, porque sao incluidos em cada controller pela chamada
# active_scaffold e ficariam na frente de um metodo do ApplicationController.
module ActiveScaffoldInplaceEditUpdate
  # A recusa vem antes de a acao da gem carregar o registro: a resposta dela,
  # mesmo a de falha, traz o valor da coluna pedida.
  def update_column
    column = active_scaffold_config.columns[params[:column]]
    raise ActiveScaffold::ActionNotAllowed unless column&.inplace_edit

    super
  end
end

module ActiveScaffoldInplaceEditField
  protected
    def render_field_for_inplace_editing
      column = active_scaffold_config.columns[params[:update_column]]
      raise ActiveScaffold::ActionNotAllowed unless column&.inplace_edit

      super
    end
end

ActiveScaffold::Actions::Update.prepend(ActiveScaffoldInplaceEditUpdate)
ActiveScaffold::Actions::Core.prepend(ActiveScaffoldInplaceEditField)
