# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddColumnsToRankingConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :ranking_configs, :form_condition_id, :integer
    add_column :ranking_configs, :behavior_on_invalid_condition, :string, default: I18n.t(
      "activerecord.attributes.admissions/ranking_config.behavior_on_invalid_conditions.exception_on_machine"
    )
    add_column :ranking_configs, :behavior_on_invalid_ranking, :string, default: I18n.t(
      "activerecord.attributes.admissions/ranking_config.behavior_on_invalid_rankings.exception"
    )
    add_index :ranking_configs, :form_condition_id
  end
end
