# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class RemoveLevelIdFromStudents < ActiveRecord::Migration[5.1]
  def self.up
    remove_column :students, :level_id
  end

  def self.down
    add_column :students, :level_id, :integer, :references => "levels"
  end
end
