# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateScholarshipSuspensions < ActiveRecord::Migration[5.1]
  def change
    create_table :scholarship_suspensions do |t|
      t.date :start_date
      t.date :end_date
      t.boolean :active, :default => true
      t.references :scholarship_duration

      t.timestamps
    end
    #add_index :scholarship_suspensions, :scholarship_duration_id
  end
end
