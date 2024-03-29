# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateCourses < ActiveRecord::Migration[5.1]
  def self.up
    create_table :courses do |t|
      t.string :name
      t.references :level
      t.references :institution

      t.timestamps
    end
  end

  def self.down
    drop_table :courses
  end
end
