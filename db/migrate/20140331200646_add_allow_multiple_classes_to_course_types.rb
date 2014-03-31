class AddAllowMultipleClassesToCourseTypes < ActiveRecord::Migration
  def change
    add_column :course_types, :allow_multiple_classes, :boolean, null: false , default: false, after: :has_score
  end
end
