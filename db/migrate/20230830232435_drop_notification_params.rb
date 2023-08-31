# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class DropNotificationParams < ActiveRecord::Migration[7.0]
  def change
    drop_table :notification_params do |t|
      t.integer :notification_id
      t.integer :query_param_id
      t.string :value, limit: 255
      t.datetime :created_at, precision: nil, null: false
      t.datetime :updated_at, precision: nil, null: false
      t.boolean :active, default: false, null: false
    end
  end
end
