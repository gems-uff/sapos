class AddReplyToToNotificationLogs < ActiveRecord::Migration[7.0]
  def up
    add_column :notification_logs, :reply_to, :string, limit: 255
  end
  def change
    remove_column :notification_logs, :reply_to
  end
end
