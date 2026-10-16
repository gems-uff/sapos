# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ChangeCarrierWaveFileBinaryLimitToLongblob < ActiveRecord::Migration[5.1]
  def up
    change_column :carrier_wave_files, :binary, :binary, limit: 4294967295
  end

  def down
    change_column :carrier_wave_files, :binary, :binary, limit: 16777215
  end
end
