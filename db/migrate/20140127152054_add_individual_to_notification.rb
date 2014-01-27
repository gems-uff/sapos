class AddIndividualToNotification < ActiveRecord::Migration
  def change
    add_column :notifications, :individual, :boolean, default: true
  end
end
