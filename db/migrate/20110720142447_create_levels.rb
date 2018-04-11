# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateLevels < ActiveRecord::Migration[5.1]
  def self.up
    create_table :levels do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :levels
  end
end
