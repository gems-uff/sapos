class AddActiveToNotificationParams < ActiveRecord::Migration
  def change
    add_column :notification_params, :active, :boolean, default: false, after: :id, null: false
  end
end
