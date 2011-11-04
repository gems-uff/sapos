class CreatePhases < ActiveRecord::Migration
  def self.up
    create_table :phases do |t|
      t.string :name
      t.string :description
      t.integer :deadline

      t.timestamps
    end
  end

  def self.down
    drop_table :phases
  end
end
