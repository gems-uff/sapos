# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddToAndSubjectAndBodyToNotificationLog < ActiveRecord::Migration[5.1]
  def change
    add_column :notification_logs, :to, :string
    add_column :notification_logs, :subject, :string
    add_column :notification_logs, :body, :text
  end
end
