# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateGrants < ActiveRecord::Migration[7.0]
  def change
    create_table :grants do |t|
      t.string :title
      t.integer :start_year
      t.integer :end_year
      t.string :kind
      t.string :funder
      t.decimal :amount, precision: 14, scale: 2
      t.references :professor, null: false, foreign_key: true

      t.timestamps
    end
  end
end
