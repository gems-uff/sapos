# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateFilledFormField < ActiveRecord::Migration[7.0]
  def change
    create_table :filled_form_fields do |t|
      t.integer :filled_form_id
      t.integer :form_field_id
      t.text :value
      t.string :list
      t.string :file

      t.timestamps
    end
    add_index :filled_form_fields, :filled_form_id
    add_index :filled_form_fields, :form_field_id
  end
end
