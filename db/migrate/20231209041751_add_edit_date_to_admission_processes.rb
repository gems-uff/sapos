# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddEditDateToAdmissionProcesses < ActiveRecord::Migration[7.0]
  def change
    add_column :admission_processes, :edit_date, :date
  end
end
