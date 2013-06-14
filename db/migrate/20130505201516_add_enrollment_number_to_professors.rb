# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddEnrollmentNumberToProfessors < ActiveRecord::Migration
  def self.up
    add_column :professors, :enrollment_number, :string
  end

  def self.down
    remove_column :professors, :enrollment_number
  end
end
