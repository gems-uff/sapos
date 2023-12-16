# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateAdmissionRankingResults < ActiveRecord::Migration[7.0]
  def change
    create_table :admission_ranking_results do |t|
      t.integer :ranking_config_id
      t.integer :admission_application_id
      t.integer :filled_form_id

      t.timestamps
    end
    add_index :admission_ranking_results, :ranking_config_id
    add_index :admission_ranking_results, :admission_application_id
    add_index :admission_ranking_results, :filled_form_id
  end
end
