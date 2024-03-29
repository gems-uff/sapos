# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class UpdateOffsetsColumnsOfNotification < ActiveRecord::Migration[5.1]
  def up
    change_column :notifications, :query_offset, :string
    change_column :notifications, :notification_offset, :string
  end

  def down
  end
end
