# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddProfessorToScholarship < ActiveRecord::Migration
  def self.up
    add_column :scholarships, :professor_id, :integer
  end

  def self.down
    remove_column :scholarships, :professor_id
  end
end