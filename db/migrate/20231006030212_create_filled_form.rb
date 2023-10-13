# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateFilledForm < ActiveRecord::Migration[7.0]
  def change
    create_table :filled_forms do |t|
      t.integer :form_template_id
      t.boolean :is_filled

      t.timestamps
    end
    add_index :filled_forms, :form_template_id
  end
end
