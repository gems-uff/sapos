class AddNotSchedulableToCourseClasses < ActiveRecord::Migration[6.0]
  def change
    add_column :course_classes, :not_schedulable, :boolean, default: false
  end
end
