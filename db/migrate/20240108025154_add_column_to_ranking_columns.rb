# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddColumnToRankingColumns < ActiveRecord::Migration[7.0]
  def change
    add_column :ranking_columns, :admission_report_config_id, :integer
    add_index :ranking_columns, :admission_report_config_id
  end
end
