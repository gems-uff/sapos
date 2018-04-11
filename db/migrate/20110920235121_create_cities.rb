# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateCities < ActiveRecord::Migration[5.1]
  def self.up
    create_table :cities do |t|
      t.string :name
      t.references :state

      t.timestamps
    end
  end

  def self.down
    drop_table :cities
  end
end
