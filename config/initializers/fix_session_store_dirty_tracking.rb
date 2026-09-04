# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# O activerecord-session_store so grava a linha da sessao quando o registro
# parece sujo:
#
#   record.data = session_data
#   return sid unless record.changed? || record.new_record?
#
# Mas os dois lados dessa comparacao compartilham os mesmos objetos. O
# get_session devolve `record.data` para o Rack, e o Rails guarda esse hash com
# `@delegate.replace(session.stringify_keys)` -- que refaz so o nivel de cima e
# reaproveita os valores. Quem escreve no topo (`session[:x] = y`) troca o valor
# de um lado so, a comparacao acusa, e a linha e gravada. Quem **muta em lugar**
# um valor aninhado muta o hash dos dois lados de uma vez: `record.data` ja
# nasce com o valor novo, `changed?` da falso, e a gravacao nunca acontece.
#
# O active_scaffold guarda filtro, ordenacao e pagina exatamente assim:
# `active_scaffold_session_storage` faz `session[chave] ||= {}` -- escrita no
# topo apenas na primeira vez -- e daí em diante os chamadores mutam o hash
# devolvido. O efeito e que a linha congela no estado da primeira requisicao:
# a primeira filtragem gruda, e toda troca de filtro posterior e descartada ao
# fim da requisicao. Foi o que produziu a #660 (paginar depois de trocar o
# filtro devolve as linhas do filtro anterior), e alcanca tambem a ordenacao de
# coluna e qualquer link que dependa da busca guardada.
#
# A correcao devolve sentido a comparacao: o hash entregue ao Rack passa a ser
# copia profunda, entao `record.data` guarda o estado como veio do banco e
# mutacao em lugar volta a ser visivel. O caminho que ja funcionava nao muda, e
# requisicao que nao mexe na sessao continua sem gravar nada.
#
# O gancho e o `find_session`, nao o `get_session`: quem carrega a sessao no
# activerecord-session_store e aquele. O `get_session` continua definido na
# mesma classe, mas ninguem o chama -- patch aplicado nele passa despercebido.
module SaposSessionStoreDirtyTracking
  private
    def find_session(request, id)
      id, data = super
      [id, data.deep_dup]
    end
end

ActionDispatch::Session::ActiveRecordStore.prepend(SaposSessionStoreDirtyTracking)
