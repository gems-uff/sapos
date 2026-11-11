class BackfillCourseClassProfessorsFromCourseClasses < ActiveRecord::Migration[7.1]
  class CourseClass < ActiveRecord::Base
    self.table_name = "course_classes"
  end

  class CourseClassProfessor < ActiveRecord::Base
    self.table_name = "course_class_professors"
  end

  def up
    CourseClass.where.not(professor_id: nil).find_each do |course_class|
      CourseClassProfessor.find_or_create_by!(
        course_class_id: course_class.id,
        professor_id: course_class.professor_id
      )
    end
  end

  def down
    CourseClass.find_each do |course_class|
      professor_ids = CourseClassProfessor
        .where(course_class_id: course_class.id)
        .pluck(:professor_id)

      next if professor_ids.empty?

      raise ActiveRecord::IrreversibleMigration,
        "Course class #{course_class.id} has multiple professors" if professor_ids.many?

      course_class.update!(professor_id: professor_ids.first)
    end

    CourseClassProfessor.delete_all

    # CourseClassProfessor.where.not(professor_id: nil).find_each do |course_class_professor|
    #   course_class = CourseClass.find(course_class_professor.course_class_id)
    #   course_class.update(professor_id: course_class_professor.professor_id)
    # end
    # CourseClassProfessor.delete_all
  end
end
