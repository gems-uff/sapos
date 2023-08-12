# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreatePhaseDurations < ActiveRecord::Migration[5.1]
  def self.up
    create_table :phase_durations do |t|
      t.references :phase
      t.references :level
      t.integer :deadline

      t.timestamps
    end
  end

  def self.down
    drop_table :phase_durations
  end
end
