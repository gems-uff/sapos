# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddExtendOnHoldToPhases < ActiveRecord::Migration[5.1]
  def change
    add_column :phases, :extend_on_hold, :boolean, :default => false
  end
end
