# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddAcronymToInstitution < ActiveRecord::Migration
  def self.up
    add_column :institutions, :code, :string
  end

  def self.down
    remove_column :institutions, :code
  end
end
