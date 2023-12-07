# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateAdmissionPendency < ActiveRecord::Migration[7.0]
  def change
    create_table :admission_pendencies do |t|
      t.integer :admission_application_id
      t.integer :admission_phase_id
      t.integer :user_id
      t.string :mode
      t.string :status, default: "Pendente"

      t.timestamps
    end
    add_index :admission_pendencies, :admission_application_id
    add_index :admission_pendencies, :admission_phase_id
    add_index :admission_pendencies, :user_id
  end
end
