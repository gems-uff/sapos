class AddReplyToToNotificationLogs < ActiveRecord::Migration[7.0]
  def change
    add_column :notification_logs, :reply_to, :string, limit: 255
  end
end
