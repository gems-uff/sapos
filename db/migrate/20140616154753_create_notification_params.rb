# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateNotificationParams < ActiveRecord::Migration[5.1]
  def up
    create_table :notification_params, force: true do |t|
      t.integer :notification_id
      t.integer :query_param_id
      t.string :value
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :notification_params, [:query_param_id]
    add_index :notification_params, [:notification_id]
  end

  def down
    drop_table :notification_params
  end
end
