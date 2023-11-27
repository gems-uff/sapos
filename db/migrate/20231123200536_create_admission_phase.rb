# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateAdmissionPhase < ActiveRecord::Migration[7.0]
  def change
    create_table :admission_phases do |t|
      t.string :name
      t.integer :member_form_id
      t.integer :shared_form_id
      t.integer :consolidation_form_id
      t.boolean :can_edit_candidate

      t.timestamps
    end
    add_index :admission_phases, :member_form_id
    add_index :admission_phases, :shared_form_id
    add_index :admission_phases, :consolidation_form_id
  end
end
