# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateFilledFormFieldScholarity < ActiveRecord::Migration[7.0]
  def change
    create_table :filled_form_field_scholarities do |t|
      t.integer :filled_form_field_id
      t.string :level
      t.string :status
      t.date :date

      t.timestamps
    end
    add_index :filled_form_field_scholarities, :filled_form_field_id
  end
end
