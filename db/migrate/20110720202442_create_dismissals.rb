# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateDismissals < ActiveRecord::Migration
  def self.up
    create_table :dismissals do |t|
      t.date :date
      t.references :enrollment
      t.references :dismissal_reason
      t.text :obs

      t.timestamps
    end
  end

  def self.down
    drop_table :dismissals
  end
end
