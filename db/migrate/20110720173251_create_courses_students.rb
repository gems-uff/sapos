class CreateCoursesStudents < ActiveRecord::Migration
  def self.up
    create_table :courses_students, :id => false do |t|
      t.references :course, :null => false
      t.references :student, :null => false    
    end
    
    add_index :courses_students, :course_id
    add_index :courses_students, :student_id
  end

  def self.down
    drop_table :courses_students
  end
end