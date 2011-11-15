class RemoveDeadlineFromPhase < ActiveRecord::Migration
  def self.up
    remove_column(:phases, :deadline)
  end

  def self.down
    add_column(:phases, :deadline, :integer)
  end
end
