# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateClassEnrollmentRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :class_enrollment_requests do |t|
      t.references :enrollment_request
      t.references :course_class
      t.references :class_enrollment
      t.string :status, default: "Solicitada"

      t.timestamps
    end
  end
end
