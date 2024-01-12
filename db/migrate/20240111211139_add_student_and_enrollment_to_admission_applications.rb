# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddStudentAndEnrollmentToAdmissionApplications < ActiveRecord::Migration[7.0]
  def change
    add_column :admission_applications, :student_id, :integer
    add_column :admission_applications, :enrollment_id, :integer
    add_index :admission_applications, :student_id
    add_index :admission_applications, :enrollment_id

    add_column :admission_processes, :level_id, :integer
    add_column :admission_processes, :enrollment_status_id, :integer
    add_column :admission_processes, :enrollment_number_field, :string
    add_column :admission_processes, :admission_date, :date
    add_index :admission_processes, :level_id
    add_index :admission_processes, :enrollment_status_id
  end
end
