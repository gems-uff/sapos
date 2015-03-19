# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreatePhaseCompletions < ActiveRecord::Migration
  def change
    create_table :phase_completions do |t|
      t.integer :enrollment_id
      t.integer :phase_id
      t.datetime :due_date
      t.datetime :completion_date

      t.timestamps
    end
  end
end
