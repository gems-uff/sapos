# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ChangeAdmissionProcessPhaseDateTimesToDate < ActiveRecord::Migration[7.0]
  def up
    change_column :admission_process_phases, :start_date, :date
    change_column :admission_process_phases, :end_date, :date
  end

  def down
    change_column :admission_process_phases, :start_date, :datetime
    change_column :admission_process_phases, :end_date, :datetime
  end
end
