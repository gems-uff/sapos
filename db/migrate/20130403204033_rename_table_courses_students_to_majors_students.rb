class RenameTableCoursesStudentsToMajorsStudents < ActiveRecord::Migration
  def self.up
    rename_table :courses_students, :majors_students
  end
  def self.down
    rename_table :majors_students, :courses_students
  end
end
