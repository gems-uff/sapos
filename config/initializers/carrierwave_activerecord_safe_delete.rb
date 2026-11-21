# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# A storage do fork carrierwave-activerecord guarda bytes iguais numa linha so
# de carrier_wave_files, com mais de um dono. Quem apagava a linha olhando um
# dono so deixava os outros apontando para o nada: o CarrierWave ao excluir um
# dono (after_commit do destroy) e ao desfazer uma gravacao (after_rollback),
# e, antes da #696, a limpeza de documento vencido.
#
# Aqui a linha so se apaga por destroy_unreferenced!, que trava a linha,
# confere que nenhuma coluna aponta para ela e so entao apaga. E o caminho do
# coletor de orfaos. O resto:
#
# - a storage ignora o pedido de apagar, que o CarrierWave faz nos fluxos
#   normais de excluir e desfazer;
# - o model (destroy, delete) e a limpeza em bloco da storage recusam com
#   erro, para que um codigo novo que tente apagar falhe a vista.
#
# O reaproveitamento de uma linha existente trava a linha e atualiza a data
# dela dentro da gravacao do dono novo. Assim o coletor ou espera essa
# gravacao terminar e ve o dono novo, ou apaga antes e a gravacao cria outra
# linha; e o arquivo gerado sem model (PdfUploader), que grava o dono depois,
# fica protegido pela idade minima.
#
# Sai junto com o fork, na troca do armazenamento (#672).
module CarrierWaveActiveRecordSafeDelete
  class Blocked < StandardError
    def initialize(msg = "arquivo guardado so se apaga por destroy_unreferenced!")
      super
    end
  end

  # Toda coluna que guarda o identificador (medium_hash) de um arquivo.
  # spec/config/carrierwave_safe_delete_spec.rb confere a lista contra os
  # uploaders montados.
  REFERENCES_BY_HASH = {
    "Admissions::FilledFormField" => :file,
    "Student" => :photo,
    "ReportConfiguration" => :image
  }.freeze

  def self.referenced?(row)
    REFERENCES_BY_HASH.any? { |model, column| model.constantize.exists?(column => row.medium_hash) } ||
      Report.exists?(carrierwave_file_id: row.id)
  end

  def self.permitting
    previous = ActiveSupport::IsolatedExecutionState[:carrierwave_safe_delete]
    ActiveSupport::IsolatedExecutionState[:carrierwave_safe_delete] = true
    yield
  ensure
    ActiveSupport::IsolatedExecutionState[:carrierwave_safe_delete] = previous
  end

  def self.permitted?
    ActiveSupport::IsolatedExecutionState[:carrierwave_safe_delete] == true
  end

  # O model da tabela.
  module Row
    # Apaga a linha se nada aponta para ela e se ela nao foi gravada nem
    # reaproveitada ha menos de older_than. Devolve true se apagou.
    def destroy_unreferenced!(older_than: 1.hour)
      self.class.transaction do
        lock!
        next false if updated_at > older_than.ago
        next false if CarrierWaveActiveRecordSafeDelete.referenced?(self)
        CarrierWaveActiveRecordSafeDelete.permitting { destroy! }
        true
      end
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
    def create!(uploader, new_file, identifier)
      CarrierWave::Storage::ActiveRecord::ActiveRecordFile.transaction do
        CarrierWave::Storage::ActiveRecord::ActiveRecordFile
          .lock.find_by(medium_hash: identifier)&.touch
        super
      end
    end

    def delete_all
      raise Blocked
    end
  end
end

CarrierWave::Storage::ActiveRecord::ActiveRecordFile.include(CarrierWaveActiveRecordSafeDelete::Row)
CarrierWave::Storage::ActiveRecord::ActiveRecordFile.before_destroy do
  raise CarrierWaveActiveRecordSafeDelete::Blocked unless CarrierWaveActiveRecordSafeDelete.permitted?
end
CarrierWave::Storage::ActiveRecord::File.prepend(CarrierWaveActiveRecordSafeDelete::StoredFile)
CarrierWave::Storage::ActiveRecord::File.singleton_class.prepend(
  CarrierWaveActiveRecordSafeDelete::StoredFileClassMethods
)
