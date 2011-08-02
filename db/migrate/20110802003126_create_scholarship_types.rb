class CreateScholarshipTypes < ActiveRecord::Migration
  def self.up
    create_table :scholarship_types do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :scholarship_types
  end
end
