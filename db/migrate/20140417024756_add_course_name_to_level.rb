class AddCourseNameToLevel < ActiveRecord::Migration
  def change
    add_column :levels, :course_name, :string
  end
end
