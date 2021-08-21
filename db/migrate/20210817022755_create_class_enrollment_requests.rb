class CreateClassEnrollmentRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :class_enrollment_requests do |t|
      t.references :enrollment_request, foreign_key: true
      t.references :course_class, foreign_key: true
      t.references :class_enrollment, foreign_key: true
      t.string :status, default: "Solicitada"

      t.timestamps
    end
  end
end
