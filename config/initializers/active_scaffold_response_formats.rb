# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# ActiveScaffold::Actions::Core#default_formats oferece JSON e XML em toda acao
# de todo scaffold: /<scaffold>.json devolve as colunas da listagem cruas e,
# para cada coluna de associacao, o registro associado com todos os atributos
# (response_to_api). Essa resposta nao passa pelos helpers de coluna nem pelo
# que a tela esconde por papel, e nenhuma tela do SAPOS a usa: o JavaScript da
# gem e o do SAPOS pedem HTML e JS. Aqui o scaffold so responde nesses dois; o
# pedido em outro formato recebe 406 (ActionController::UnknownFormat).
#
# As acoes que o SAPOS escreve com respond_to proprio (autocomplete, cidades e
# estados, modelo de e-mail) nao passam por aqui.
#
# Prepend no modulo, porque ele e incluido em cada controller pela chamada
# active_scaffold e ficaria na frente de um metodo do ApplicationController.
module ActiveScaffoldResponseFormats
  protected
    def default_formats
      %i[html js]
    end
end

ActiveScaffold::Actions::Core.prepend(ActiveScaffoldResponseFormats)
