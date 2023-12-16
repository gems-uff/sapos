# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateAdmissionProcessRankings < ActiveRecord::Migration[7.0]
  def change
    create_table :admission_process_rankings do |t|
      t.integer :ranking_config_id
      t.integer :admission_process_id
      t.integer :admission_phase_id

      t.timestamps
    end
    add_index :admission_process_rankings, :ranking_config_id
    add_index :admission_process_rankings, :admission_process_id
    add_index :admission_process_rankings, :admission_phase_id
  end
end
