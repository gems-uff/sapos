# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddEnrollmentNumberToProfessors < ActiveRecord::Migration[5.1]
  def self.up
    add_column :professors, :enrollment_number, :string
  end

  def self.down
    remove_column :professors, :enrollment_number
  end
end
