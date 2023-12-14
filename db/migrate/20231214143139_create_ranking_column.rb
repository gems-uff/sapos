# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateRankingColumn < ActiveRecord::Migration[7.0]
  def change
    create_table :ranking_columns do |t|
      t.integer :ranking_config_id
      t.string :name
      t.string :order

      t.timestamps
    end

    add_index :ranking_columns, :ranking_config_id
  end
end
