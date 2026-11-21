# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateImportGradePreviews < ActiveRecord::Migration[8.1]
  def up
    create_table :import_grade_previews do |t|
      t.string :token, null: false
      t.references :course_class, null: false
      t.references :user, null: false
      t.text :data, null: false, limit: 16.megabytes
      t.datetime :created_at, null: false
    end
    add_index :import_grade_previews, :token, unique: true
  end

  def down
    drop_table :import_grade_previews
  end
end