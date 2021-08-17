class CreateClassEnrollmentRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :class_enrollment_requests do |t|
      t.references :enrollment_request, foreign_key: true
      t.references :course_class, foreign_key: true
      t.string :status_professor, default: "Indefinido"
      t.string :status_coord, default: "Indefinido"

      t.timestamps
    end
  end
end
