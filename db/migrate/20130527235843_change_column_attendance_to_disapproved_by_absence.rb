# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ChangeColumnAttendanceToDisapprovedByAbsence < ActiveRecord::Migration[5.1]
  def self.up
    remove_column :class_enrollments, :attendance
    add_column :class_enrollments, :disapproved_by_absence, :boolean, :default => false
  end

  def self.down
    remove_column :class_enrollments, :disapproved_by_absence
    add_column :class_enrollments, :attendance, :boolean
  end
end
