class AddBodyToNotification < ActiveRecord::Migration
  def change
    change_column :notifications, :body_template, :text, :limit => nil
  end
end
