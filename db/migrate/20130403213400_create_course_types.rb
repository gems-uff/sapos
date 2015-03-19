# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateCourseTypes < ActiveRecord::Migration
  def self.up
    create_table :course_types do |t|
      t.string :name
      t.boolean :has_score

      t.timestamps
    end
  end

  def self.down
    drop_table :course_types
  end
end
