# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateDeferrals < ActiveRecord::Migration[5.1]
  def self.up
    create_table :deferrals do |t|
      t.date :approval_date
      t.string :obs
      t.references :enrollment
      t.references :deferral_type

      t.timestamps
    end
  end

  def self.down
    drop_table :deferrals
  end
end
