# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateEnrollments < ActiveRecord::Migration[5.1]
  def self.up
    create_table :enrollments do |t|
      t.string :enrollment_number
      t.references :student
      t.references :level
      t.references :enrollment_status
      t.date :admission_date
      t.text :obs

      t.timestamps
    end
  end

  def self.down
    drop_table :enrollments
  end
end
