class AddIsEnabledToApplicationProcess < ActiveRecord::Migration
  def change
    add_column :application_processes, :is_enabled, :boolean, :default => true
  end
end
