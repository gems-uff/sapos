# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateClassSchedules < ActiveRecord::Migration[6.0]
  def change
    create_table :class_schedules do |t|
      t.integer :year
      t.integer :semester
      t.datetime :enrollment_start
      t.datetime :enrollment_end

      t.timestamps
    end
  end
end
