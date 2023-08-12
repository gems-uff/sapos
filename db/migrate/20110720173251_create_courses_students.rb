# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateCoursesStudents < ActiveRecord::Migration[5.1]
  def self.up
    create_table :courses_students, id: false do |t|
      t.references :course, null: false
      t.references :student, null: false
    end
  end

  def self.down
    drop_table :courses_students
  end
end
