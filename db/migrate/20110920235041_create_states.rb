# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateStates < ActiveRecord::Migration[5.1]
  def self.up
    create_table :states do |t|
      t.string :name
      t.string :code
      t.references :country

      t.timestamps
    end
  end

  def self.down
    drop_table :states
  end
end
