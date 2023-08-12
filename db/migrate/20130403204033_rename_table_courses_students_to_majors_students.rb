# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class RenameTableCoursesStudentsToMajorsStudents < ActiveRecord::Migration[5.1]
  def self.up
    rename_table :courses_students, :majors_students
  end
  def self.down
    rename_table :majors_students, :courses_students
  end
end
