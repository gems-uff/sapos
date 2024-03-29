# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateVersions < ActiveRecord::Migration[5.1]
  def self.up
    create_table :versions do |t|
      t.string   :item_type, null: false
      t.integer  :item_id, null: false, foreign_key: false
      t.string   :event, null: false
      t.string   :whodunnit
      t.text     :object
      t.datetime :created_at
    end
    add_index :versions, [:item_type, :item_id]
  end

  def self.down
    remove_index :versions, [:item_type, :item_id]
    drop_table :versions
  end
end
