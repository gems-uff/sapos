class CreateCourseClassProfessors < ActiveRecord::Migration[7.1]
  def change
    create_table :course_class_professors do |t|
      t.references :course_class, null: false, index: true
      t.references :professor, null: false, index: true

      t.timestamps
    end

    add_index :course_class_professors, [:course_class_id, :professor_id], unique: true, name: "index_course_class_professors_on_course_class_and_professor"
  end
end
