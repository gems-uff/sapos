# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateAccomplishments < ActiveRecord::Migration[5.1]
  def self.up
    create_table :accomplishments do |t|
      t.references :enrollment
      t.references :phase
      t.date :conclusion_date
      t.string :obs

      t.timestamps
    end
  end

  def self.down
    drop_table :accomplishments
  end
end
