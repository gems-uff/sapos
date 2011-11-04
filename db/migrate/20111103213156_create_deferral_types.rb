class CreateDeferralTypes < ActiveRecord::Migration
  def self.up
    create_table :deferral_types do |t|
      t.string :name
      t.string :description
      t.integer :duration
      t.references :phase

      t.timestamps
    end
  end

  def self.down
    drop_table :deferral_types
  end
end
