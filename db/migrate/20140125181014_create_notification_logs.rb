class CreateNotificationLogs < ActiveRecord::Migration
  def change
    create_table :notification_logs do |t|
      t.references :notification

      t.timestamps
    end
    add_index :notification_logs, :notification_id
  end
end
