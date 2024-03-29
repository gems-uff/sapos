# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateCourses2 < ActiveRecord::Migration[5.1]
  def self.up
    create_table :courses do |t|
      t.string :name
      t.string :code
      t.text :content
      t.integer :credits
      t.references :research_area
      t.references :course_type

      t.timestamps
    end
  end

  def self.down
    drop_table :courses
  end
end
