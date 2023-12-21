# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddKeepInPhaseConditionToAdmissionPhases < ActiveRecord::Migration[7.0]
  def change
    add_column :admission_phases, :keep_in_phase_condition_id, :integer
    add_index :admission_phases, :keep_in_phase_condition_id
  end
end
