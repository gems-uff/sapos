class CreateCourseClasses < ActiveRecord::Migration
  def self.up
    create_table :course_classes do |t|
      t.string :name
      t.references :course
      t.references :professor

      t.timestamps
    end
  end

  def self.down
    drop_table :course_classes
  end
end
