# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Os arquivos enviados (anexo de candidatura, foto, documento assinado) moram
# em carrier_wave_files.binary. A migration 20170915225335 (#230) ja tinha
# subido a coluna de BLOB (64 KB) para MEDIUMBLOB (16 MB), mas o limite nao
# chegou ao db/schema.rb, e toda instalacao montada por db:schema:load desde
# entao, assim como o banco do CI, nasceu com BLOB:
# o primeiro arquivo acima de 64 KB responde 500 (Data too long). Esta repete a
# mudanca (#737); onde a coluna ja e MEDIUMBLOB, nada muda.
class RestoreMediumBlobInCarrierWaveFiles < ActiveRecord::Migration[8.1]
  def up
    change_column :carrier_wave_files, :binary, :binary, limit: 16_777_215
  end

  def down
    # Sem volta: reduzir a coluna truncaria os arquivos acima de 64 KB.
  end
end
