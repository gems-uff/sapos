class CreateAccomplishments < ActiveRecord::Migration
  def self.up
    create_table :accomplishments do |t|
      t.references :enrollment
      t.references :phase
      t.date :conclusion_date
      t.string :obs

      t.timestamps
    end
  end

  def self.down
    drop_table :accomplishments
  end
end
