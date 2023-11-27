# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateFormCondition < ActiveRecord::Migration[7.0]
  def change
    create_table :form_conditions do |t|
      t.references :model, polymorphic: true, null: false
      t.string :field
      t.string :condition
      t.string :value

      t.timestamps
    end
    add_index :form_conditions, :field
  end
end
