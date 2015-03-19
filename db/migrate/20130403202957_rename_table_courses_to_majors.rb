# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class RenameTableCoursesToMajors < ActiveRecord::Migration
  def self.up
    rename_table :courses, :majors
    remove_foreign_key :courses_students, "courses_students_course_id_fkey"
    rename_column :courses_students, :course_id, :major_id
    add_foreign_key "courses_students", ["major_id"], "majors", ["id"]
  end
  def self.down
    rename_table :majors, :courses
    rename_column :courses_students, :major_id, :course_id
  end
end
