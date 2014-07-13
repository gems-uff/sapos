class CreateScholarshipSuspensions < ActiveRecord::Migration
  def change
    create_table :scholarship_suspensions do |t|
      t.date :start_date
      t.date :end_date
      t.boolean :active, :default => true
      t.references :scholarship_duration

      t.timestamps
    end
    add_index :scholarship_suspensions, :scholarship_duration_id
  end
end
