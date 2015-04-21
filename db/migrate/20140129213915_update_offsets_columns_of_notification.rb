# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class UpdateOffsetsColumnsOfNotification < ActiveRecord::Migration
  def up
  	change_column :notifications, :query_offset, :string
  	change_column :notifications, :notification_offset, :string
  end

  def down
  end
end
