# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateConfigurations < ActiveRecord::Migration[5.1]
  def change
    create_table :configurations do |t|
      t.string :name
      t.string :variable
      t.string :value

      t.timestamps
    end
  end
end
