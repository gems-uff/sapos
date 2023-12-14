# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateRankingProcess < ActiveRecord::Migration[7.0]
  def change
    create_table :ranking_processes do |t|
      t.integer :ranking_config_id
      t.integer :order
      t.integer :vacancies
      t.string :group
      t.integer :ranking_machine_id

      t.timestamps
    end
    add_index :ranking_processes, :ranking_config_id
    add_index :ranking_processes, :ranking_machine_id
  end
end
