# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateScholarshipDurations < ActiveRecord::Migration[5.1]
  def self.up
    create_table :scholarship_durations do |t|
      t.references :scholarship, :null => false
      t.references :enrollment, :null => false
      t.date :start_date
      t.date :end_date
      t.text :obs

      t.timestamps
    end
    
    add_index :scholarship_durations, :scholarship_id
    add_index :scholarship_durations, :enrollment_id
  end

  def self.down
    drop_table :scholarship_durations
  end
end
