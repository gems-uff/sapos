# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateCarrierwaveOrphanFiles < ActiveRecord::Migration[7.1]
  def change
    create_table :carrierwave_orphan_files do |t|
      t.integer :carrierwave_file_id, null: false
      t.string :original_model

      t.timestamps null: false
    end

    add_index :carrierwave_orphan_files, :carrierwave_file_id, unique: true
    add_index :carrierwave_orphan_files, :original_model

    add_index :students, :photo, if_not_exists: true
    add_index :report_configurations, :image, if_not_exists: true
    add_index :filled_form_fields, :file, if_not_exists: true
    add_index :reports, :carrierwave_file_id, if_not_exists: true
  end
end
