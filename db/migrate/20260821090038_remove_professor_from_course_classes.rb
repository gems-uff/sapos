class RemoveProfessorFromCourseClasses < ActiveRecord::Migration[7.1]
  class CourseClass < ActiveRecord::Base
    self.table_name = "course_classes"
  end

  class CourseClassProfessor < ActiveRecord::Base
    self.table_name = "course_class_professors"
  end

  def up
    remove_index :course_classes, :professor_id
    remove_column :course_classes, :professor_id
  end

  def down
    add_reference :course_classes, :professor, index: true

    CourseClassProfessor.find_each do |course_class_professor|
      CourseClass.where(
        id: course_class_professor.course_class_id,
        professor_id: nil
      ).update_all(professor_id: course_class_professor.professor_id)
    end
  end
end
