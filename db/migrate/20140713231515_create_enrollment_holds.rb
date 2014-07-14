class CreateEnrollmentHolds < ActiveRecord::Migration
  def change
    create_table :enrollment_holds do |t|
      t.references :enrollment
      t.integer :year
      t.integer :semester
      t.integer :number_of_semesters, :default => 1

      t.timestamps
    end
    add_index :enrollment_holds, :enrollment_id
  end
end
