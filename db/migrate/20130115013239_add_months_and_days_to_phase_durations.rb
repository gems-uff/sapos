# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddMonthsAndDaysToPhaseDurations < ActiveRecord::Migration[5.1]
  def self.up
    rename_column :phase_durations, :deadline, :deadline_semesters
    add_column :phase_durations, :deadline_months, :integer, :default => 0
    add_column :phase_durations, :deadline_days, :integer, :default => 0
  end

  def self.down
    rename_column :phase_durations, :deadline_semesters, :deadline
    remove_column :phase_durations, :deadline_months
    remove_column :phase_durations, :deadline_days
  end
end
