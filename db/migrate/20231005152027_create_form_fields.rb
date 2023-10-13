# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateFormFields < ActiveRecord::Migration[7.0]
  def change
    create_table :form_fields do |t|
      t.integer :form_template_id
      t.integer :order
      t.string :name
      t.string :description
      t.string :field_type
      t.string :configuration

      t.timestamps
    end
    add_index :form_fields, :form_template_id
  end
end
