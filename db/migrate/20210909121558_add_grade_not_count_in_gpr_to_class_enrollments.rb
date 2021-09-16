# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddGradeNotCountInGprToClassEnrollments < ActiveRecord::Migration[6.0]
  def up
    change_table :class_enrollments do |t|
      t.boolean :grade_not_count_in_gpr, :default => false
      t.string  :justification_grade_not_count_in_gpr, :default => ""
    end
  end

  def down
    change_table :class_enrollments do |t|
      t.remove :grade_not_count_in_gpr, :justification_grade_not_count_in_gpr
    end
  end
end

