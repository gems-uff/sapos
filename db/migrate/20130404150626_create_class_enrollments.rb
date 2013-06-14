# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateClassEnrollments < ActiveRecord::Migration
  def self.up
    create_table :class_enrollments do |t|
      t.text :obs
      t.integer :grade
      t.boolean :attendance
      t.string :situation
      t.references :course_class
      t.references :enrollment

      t.timestamps
    end
  end

  def self.down
    drop_table :class_enrollments
  end
end
