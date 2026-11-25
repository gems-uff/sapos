# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# A storage do fork carrierwave-activerecord identifica o arquivo pelo resumo
# do conteudo e, ao gravar, reaproveita a linha de carrier_wave_files que ja
# tem o mesmo identificador -- e a regravava inteira com o envio novo
# (conteudo, nome e tipo), alcancando todo registro que aponta para ela.
#
# Aqui a linha existente nunca e regravada. Conteudo igual reaproveita a linha
# como esta, com o nome de quem a gravou primeiro. Conteudo diferente com o
# mesmo identificador e recusado: o envio falha e a linha fica intacta.
#
# Prepend na classe singleton de CarrierWave::Storage::ActiveRecord::File,
# porque create! e metodo de classe. Sai junto com o fork.
module CarrierWaveActiveRecordNoOverwrite
  class ConflictingContent < StandardError; end

  def create!(uploader, new_file, identifier)
    existing = CarrierWave::Storage::ActiveRecord::ActiveRecordFile
      .find_by(medium_hash: identifier)
    return super if existing.nil?

    unless existing.binary.to_s.b == new_file.read.to_s.b
      raise ConflictingContent, "conteudo diferente para um arquivo ja guardado"
    end
    new(existing)
  end
end

CarrierWave::Storage::ActiveRecord::File.singleton_class.prepend(
  CarrierWaveActiveRecordNoOverwrite
)
