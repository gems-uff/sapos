# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ChangeAdmissionPhaseResultTypeColumnToMode < ActiveRecord::Migration[7.0]
  def change
    rename_column :admission_phase_results, :type, :mode
  end
end
