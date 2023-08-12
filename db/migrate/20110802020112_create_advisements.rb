# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateAdvisements < ActiveRecord::Migration[5.1]
  def self.up
    create_table :advisements do |t|
      t.references :professor, null: false
      t.references :enrollment, null: false
      t.boolean :main_advisor

      t.timestamps
    end
  end

  def self.down
    drop_table :advisements
  end
end
