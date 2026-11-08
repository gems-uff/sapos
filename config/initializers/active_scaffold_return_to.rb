# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# ActiveScaffold::Helpers::ControllerHelpers#main_path_to_return devolve
# params[:return_to] cru, e as views da gem o poem no href do link
# "Fechar"/"Cancelar": um return_to "javascript:..." vira codigo ao clicar.
# Aqui so endereco interno vale (url_from do Rails: caminho relativo ou o
# proprio host); o resto e descartado e o retorno volta ao padrao da gem.
#
# Prepend no modulo, porque ele e incluido em cada controller pela chamada
# active_scaffold e ficaria na frente de um metodo do ApplicationController.
module ActiveScaffoldReturnTo
  def main_path_to_return
    if params[:return_to].present? && url_from(params[:return_to].to_s).nil?
      params.delete(:return_to)
    end
    super
  end
end

ActiveScaffold::Helpers::ControllerHelpers.prepend(ActiveScaffoldReturnTo)
