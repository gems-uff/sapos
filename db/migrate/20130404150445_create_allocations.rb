# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateAllocations < ActiveRecord::Migration[5.1]
  def self.up
    create_table :allocations do |t|
      t.string :day
      t.string :room
      t.time :start_time
      t.time :end_time
      t.references :course_class

      t.timestamps
    end
  end

  def self.down
    drop_table :allocations
  end
end
