# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# A storage do fork carrierwave-activerecord guarda bytes iguais numa linha so
# de carrier_wave_files, com mais de um dono. Quem apagava a linha olhando um
# dono so deixava os outros apontando para o nada: o CarrierWave ao excluir um
# dono (after_commit do destroy) e ao desfazer uma gravacao (after_rollback),
# e, antes da #696, a limpeza de documento vencido.
#
# Aqui a linha nao se apaga pela aplicacao:
#
# - a storage ignora o pedido de apagar, que o CarrierWave faz nos fluxos
#   normais de excluir e desfazer;
# - o registro (destroy, delete) e a limpeza em bloco da storage recusam com
#   erro, para que um codigo novo que tente apagar falhe a vista.
#
# Nao ha caminho de apagar, nem para a linha sem dono: decidir que uma linha
# ficou sem dono exige travar a linha ou renovar a data dela dentro da gravacao
# de cada dono novo, e isso, em MariaDB, derruba gravacoes simultaneas (a busca
# com trava que nao acha linha segura o intervalo do indice ate o commit; a
# escrita em linha alterada depois do retrato da transacao e recusada). As
# linhas sem dono ficam ate a tabela sair, na troca do armazenamento (#672),
# junto com o fork e com este arquivo.
#
# O bloqueio alcanca o registro e a storage. Exclusao pela classe ou por
# relation (delete_all, delete_by) nao passa por callback e nao e barrada.
module CarrierWaveActiveRecordSafeDelete
  class Blocked < StandardError
    def initialize(msg = "arquivo guardado nao se apaga pela aplicacao")
      super
    end
  end

  # O embrulho que o CarrierWave usa (CarrierWave::Storage::ActiveRecord::File).
  module StoredFile
    def delete
      false
    end

    def destroy!
      false
    end
  end

  module StoredFileClassMethods
    def delete_all
      raise Blocked
    end
  end
end

CarrierWave::Storage::ActiveRecord::ActiveRecordFile.before_destroy do
  raise CarrierWaveActiveRecordSafeDelete::Blocked
end
CarrierWave::Storage::ActiveRecord::File.prepend(CarrierWaveActiveRecordSafeDelete::StoredFile)
CarrierWave::Storage::ActiveRecord::File.singleton_class.prepend(
  CarrierWaveActiveRecordSafeDelete::StoredFileClassMethods
)
