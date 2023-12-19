# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddApprovalConditionToAdmissionPhases < ActiveRecord::Migration[7.0]
  def change
    add_column :admission_phases, :approval_condition_id, :integer
    add_index :admission_phases, :ranking_config_id
  end
end
