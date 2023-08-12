# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateEnrollmentHolds < ActiveRecord::Migration[5.1]
  def change
    create_table :enrollment_holds do |t|
      t.references :enrollment
      t.integer :year
      t.integer :semester
      t.integer :number_of_semesters, default: 1

      t.timestamps
    end
  end
end
