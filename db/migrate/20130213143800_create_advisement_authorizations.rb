class CreateAdvisementAuthorizations < ActiveRecord::Migration
  def self.up
    create_table :advisement_authorizations do |t|
      t.integer :professor_id, :references => :professors
      t.integer :level_id, :references => :levels

      t.timestamps
    end
  end

  def self.down
    drop_table :advisement_authorizations
  end
end
