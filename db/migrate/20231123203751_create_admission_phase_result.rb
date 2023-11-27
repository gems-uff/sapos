# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateAdmissionPhaseResult < ActiveRecord::Migration[7.0]
  def change
    create_table :admission_phase_results do |t|
      t.integer :admission_phase_id
      t.integer :admission_application_id
      t.integer :filled_form_id
      t.string :type

      t.timestamps
    end
    add_index :admission_phase_results, :admission_phase_id
    add_index :admission_phase_results, :admission_application_id
    add_index :admission_phase_results, :filled_form_id
  end
end
