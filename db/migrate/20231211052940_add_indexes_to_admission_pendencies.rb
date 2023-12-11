# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddIndexesToAdmissionPendencies < ActiveRecord::Migration[7.0]
  def change
    add_index :admission_pendencies, [:admission_application_id, :admission_phase_id, :status],
      name: 'admission_pendencies_candidate_phase_status'
    add_index :admission_pendencies, [:admission_application_id, :user_id],
      name: 'admission_pendencies_candidate_user'
  end
end
