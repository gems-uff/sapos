# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreatePhases < ActiveRecord::Migration[5.1]
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
