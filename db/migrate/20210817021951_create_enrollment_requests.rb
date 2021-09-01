class CreateEnrollmentRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :enrollment_requests do |t|
      t.integer :year
      t.integer :semester
      t.references :enrollment
      t.string :status, default: "Solicitada"
      t.datetime :last_student_change_at
      t.datetime :last_staff_change_at

      t.timestamps
    end
  end
end
