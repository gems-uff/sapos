class AddLastExecutionToNotification < ActiveRecord::Migration
  def change
    add_column :notifications, :last_execution, :datetime
  end
end
