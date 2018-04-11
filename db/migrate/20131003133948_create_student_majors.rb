# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateStudentMajors < ActiveRecord::Migration[5.1]
  
  def self.up
  	rename_table :majors_students, :student_majors
  	add_column :student_majors, :id, :primary_key
  end

  def self.down
  	remove_column :student_majors, :id
  	rename_table :student_majors, :majors_students
  end
end
