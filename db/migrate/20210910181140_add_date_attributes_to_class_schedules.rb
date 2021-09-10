class AddDateAttributesToClassSchedules < ActiveRecord::Migration[6.0]
  def change
    add_column :class_schedules, :enrollment_adjust, :datetime
    add_column :class_schedules, :enrollment_insert, :datetime
    add_column :class_schedules, :enrollment_remove, :datetime
  end
end
