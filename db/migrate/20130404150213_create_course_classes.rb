# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateCourseClasses < ActiveRecord::Migration
  def self.up
    create_table :course_classes do |t|
      t.string :name
      t.references :course
      t.references :professor
      t.integer :year
      t.integer :semester

      t.timestamps
    end
  end

  def self.down
    drop_table :course_classes
  end
end
