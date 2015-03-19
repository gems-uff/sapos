# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreatePhases < ActiveRecord::Migration
  def self.up
    create_table :phases do |t|
      t.string :name
      t.string :description
      t.integer :deadline

      t.timestamps
    end
  end

  def self.down
    drop_table :phases
  end
end
