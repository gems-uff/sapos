# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateDismissalReasons < ActiveRecord::Migration
  def self.up
    create_table :dismissal_reasons do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :dismissal_reasons
  end
end
