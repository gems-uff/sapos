# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddStudentViewAtToEnrollmentRequest < ActiveRecord::Migration[6.0]
  def change
    add_column :enrollment_requests, :student_view_at, :datetime
  end
end
