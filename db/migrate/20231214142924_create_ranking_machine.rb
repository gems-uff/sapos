# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateRankingMachine < ActiveRecord::Migration[7.0]
  def change
    create_table :ranking_machines do |t|
      t.string :name

      t.timestamps
    end
  end
end
