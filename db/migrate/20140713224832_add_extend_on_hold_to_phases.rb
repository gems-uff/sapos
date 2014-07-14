class AddExtendOnHoldToPhases < ActiveRecord::Migration
  def change
    add_column :phases, :extend_on_hold, :boolean, :default => false
  end
end
