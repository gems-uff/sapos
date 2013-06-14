# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateDeferralTypes < ActiveRecord::Migration
  def self.up
    create_table :deferral_types do |t|
      t.string :name
      t.string :description
      t.integer :duration
      t.references :phase

      t.timestamps
    end
  end

  def self.down
    drop_table :deferral_types
  end
end
