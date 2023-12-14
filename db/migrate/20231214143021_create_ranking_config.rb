# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateRankingConfig < ActiveRecord::Migration[7.0]
  def change
    create_table :ranking_configs do |t|
      t.string :name
      t.integer :form_template_id
      t.integer :position_field_id
      t.integer :machine_field_id

      t.timestamps
    end
    add_index :ranking_configs, :form_template_id
    add_index :ranking_configs, :position_field_id
    add_index :ranking_configs, :machine_field_id
  end
end
