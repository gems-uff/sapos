# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class RemoveDeadlineFromPhase < ActiveRecord::Migration
  def self.up
    remove_column(:phases, :deadline)
  end

  def self.down
    add_column(:phases, :deadline, :integer)
  end
end
