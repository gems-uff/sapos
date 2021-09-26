class AddSchedulableToCourseClasses < ActiveRecord::Migration[6.0]
  def change
    add_column :course_classes, :schedulable, :boolean, default: true
  end
end
