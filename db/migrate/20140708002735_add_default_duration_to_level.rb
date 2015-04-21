# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddDefaultDurationToLevel < ActiveRecord::Migration
  def change
    add_column :levels, :default_duration, :integer, :default => 0
  end
end
