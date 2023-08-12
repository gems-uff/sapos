# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateRoles < ActiveRecord::Migration[5.1]
  def self.up
    create_table :roles do |t|
      t.string :name, limit: 50, null: false
      t.string :description, null: false

      t.timestamps
    end
  end

  def self.down
    drop_table :roles
  end
end
