# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddObsToStudent < ActiveRecord::Migration
  def self.up
    add_column :students, :obs, :text
  end

  def self.down
    remove_column :students, :obs
  end
end
