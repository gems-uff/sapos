# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# A linha de subformulario do active_scaffold tem uma rota em todo scaffold:
# GET edit_associated?child_association=<coluna>, que devolve uma linha nova
# de formulario para a associacao. Com associated_id=<id> a linha vem
# preenchida com um registro que ja existe ("adicionar existente"), e
# ActiveScaffold::Actions::Subform#find_associated_record o busca pelo id cru,
# em qualquer coluna de associacao do scaffold, ofereca-a o formulario ou nao.
# Para a rota basta poder alterar a classe do scaffold, o que o CanCan concede
# a quem tem regra condicional; e a linha so e segurada pela permissao de
# leitura da CLASSE associada. Classe que o papel le sob condicao vinha
# inteira, cumprisse o registro a condicao ou nao.
#
# Aqui o registro pedido pelo id sai do que o Ability deixa o usuario ler
# (accessible_by), o mesmo escopo da lista e das opcoes do seletor. O que ele
# nao le responde como o que nao existe.
#
# A mesma rota aceita a aba de um subformulario em abas (tabbed_by, value,
# value_type): a gem busca o registro da aba pelo id cru, na classe que a URL
# disser, e o atribui a linha pelo nome que a URL disser. O SAPOS nao tem
# subformulario em abas, e os tres parametros sao ignorados; quem criar um
# decide aqui o que a aba aceita.
#
# Prepend no modulo, porque ele e incluido em cada controller pela chamada
# active_scaffold e ficaria na frente de um metodo do ApplicationController.
module ActiveScaffoldSubformAssociatedRecord
  protected
    def do_edit_associated
      params.delete(:tabbed_by)
      params.delete(:value)
      params.delete(:value_type)
      super
    end

    def find_associated_record
      klass = @column.association.klass
      klass.accessible_by(current_ability, :read).find(params[:associated_id])
      super
    end
end

ActiveScaffold::Actions::Subform.prepend(ActiveScaffoldSubformAssociatedRecord)
