# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddIndexesToCarrierWaveFiles < ActiveRecord::Migration[7.0]
  def change
    add_index :carrier_wave_files, :medium_hash
    add_index :carrier_wave_files, :id
  end
end
