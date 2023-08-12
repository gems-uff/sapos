# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateCarrierwaveFiles < ActiveRecord::Migration[5.1]
  def change
    create_table :carrier_wave_files do |t|
      t.string :identifier
      t.string :medium_hash
      t.binary :binary

      t.timestamps
    end
  end
end
