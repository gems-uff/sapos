# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddAttachmentsFileNamesToNotificationLog < ActiveRecord::Migration[5.1]
  def self.up
    add_column :notification_logs, :attachments_file_names, :string
  end

  def self.down
    remove_column :notification_logs, :attachments_file_names
  end
end
