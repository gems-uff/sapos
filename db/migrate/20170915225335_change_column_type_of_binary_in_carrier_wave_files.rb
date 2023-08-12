# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ChangeColumnTypeOfBinaryInCarrierWaveFiles < ActiveRecord::Migration[5.1]
  def change
    change_column :carrier_wave_files, :binary, :binary, limit: 16777215
  end
end
