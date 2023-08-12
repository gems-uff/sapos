# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class RenameNeighbourhoodToNeighborhood < ActiveRecord::Migration[5.1]
  def change
    rename_column :professors, :neighbourhood, :neighborhood
    rename_column :students, :neighbourhood, :neighborhood
  end
end
