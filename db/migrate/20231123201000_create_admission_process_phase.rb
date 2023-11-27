# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateAdmissionProcessPhase < ActiveRecord::Migration[7.0]
  def change
    create_table :admission_process_phases do |t|
      t.integer :admission_process_id
      t.integer :admission_phase_id
      t.datetime :start_date
      t.datetime :end_date
      t.integer :order

      t.timestamps
    end

    add_index :admission_process_phases, :admission_process_id
    add_index :admission_process_phases, :admission_phase_id
  end
end
