class UpdateOffsetsColumnsOfNotification < ActiveRecord::Migration
  def up
  	change_column :notifications, :query_offset, :string
  	change_column :notifications, :notification_offset, :string
  end

  def down
  end
end
