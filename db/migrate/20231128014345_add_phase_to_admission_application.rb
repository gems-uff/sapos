# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddPhaseToAdmissionApplication < ActiveRecord::Migration[7.0]
  def change
    add_column :admission_applications, :admission_phase_id, :integer
    add_column :admission_applications, :status, :string

    add_index :admission_applications, :admission_phase_id
  end
end
