# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateAdmissionPhaseCommittee < ActiveRecord::Migration[7.0]
  def change
    create_table :admission_phase_committees do |t|
      t.integer :admission_committee_id
      t.integer :admission_phase_id

      t.timestamps
    end
    add_index :admission_phase_committees, :admission_committee_id
    add_index :admission_phase_committees, :admission_phase_id
  end
end
