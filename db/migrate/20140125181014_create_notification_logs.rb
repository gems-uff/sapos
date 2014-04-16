# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreateNotificationLogs < ActiveRecord::Migration
  def change
    create_table :notification_logs do |t|
      t.references :notification

      t.timestamps
    end
    add_index :notification_logs, :notification_id
  end
end
