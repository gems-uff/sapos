class CreateClassEnrollments < ActiveRecord::Migration
  def self.up
    create_table :class_enrollments do |t|
      t.text :obs
      t.integer :grade
      t.boolean :attendance
      t.string :situation
      t.references :course_class
      t.references :enrollment

      t.timestamps
    end
  end

  def self.down
    drop_table :class_enrollments
  end
end
