# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateDismissalReasons < ActiveRecord::Migration[5.1]
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
