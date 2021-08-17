class CreateEnrollmentRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :enrollment_requests do |t|
      t.integer :year
      t.integer :semester
      t.references :enrollment, foreign_key: true
      t.datetime :last_student_change_at
      t.datetime :last_professor_change_at
      t.datetime :last_coord_change_at

      t.timestamps
    end
  end
end
