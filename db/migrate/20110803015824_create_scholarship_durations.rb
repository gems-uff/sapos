# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateScholarshipDurations < ActiveRecord::Migration[5.1]
  def self.up
    create_table :scholarship_durations do |t|
      t.references :scholarship, null: false
      t.references :enrollment, null: false
      t.date :start_date
      t.date :end_date
      t.text :obs

      t.timestamps
    end
  end

  def self.down
    drop_table :scholarship_durations
  end
end
