# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class FixColumnName < ActiveRecord::Migration[5.1]
  def self.up
    rename_column :professors, :identity, :identity_number
  end

  def self.down
  end
end
