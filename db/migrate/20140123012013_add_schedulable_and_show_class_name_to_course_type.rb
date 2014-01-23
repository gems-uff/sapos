class AddSchedulableAndShowClassNameToCourseType < ActiveRecord::Migration
  def change
    add_column :course_types, :schedulable, :boolean
    add_column :course_types, :show_class_name, :boolean
  end
end
