# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateAdmissionProcesses < ActiveRecord::Migration[7.0]
  def change
    create_table :admission_processes do |t|
      t.string :name
      t.string :simple_url
      t.integer :semester
      t.integer :year
      t.date :start_date
      t.date :end_date
      t.integer :form_template_id
      t.integer :letter_template_id
      t.integer :min_letters
      t.integer :max_letters
      t.boolean :allow_multiple_applications
      t.boolean :visible, default: true
      t.boolean :require_session, default: true

      t.timestamps
    end
    add_index :admission_processes, :form_template_id
    add_index :admission_processes, :letter_template_id
  end
end
