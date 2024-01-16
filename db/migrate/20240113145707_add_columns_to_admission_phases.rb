# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddColumnsToAdmissionPhases < ActiveRecord::Migration[7.0]
  def change
    add_column :admission_phases, :candidate_form_id, :integer
    add_column :admission_phases, :candidate_can_edit, :boolean
    add_column :admission_phases, :candidate_can_see_member, :boolean
    add_column :admission_phases, :candidate_can_see_shared, :boolean
    add_column :admission_phases, :candidate_can_see_consolidation, :boolean
    add_index :admission_phases, :candidate_form_id

    add_column :ranking_configs, :candidate_can_see, :boolean
  end
end
