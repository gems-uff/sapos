class AddToAndSubjectAndBodyToNotificationLog < ActiveRecord::Migration
  def change
    add_column :notification_logs, :to, :string
    add_column :notification_logs, :subject, :string
    add_column :notification_logs, :body, :text
  end
end
