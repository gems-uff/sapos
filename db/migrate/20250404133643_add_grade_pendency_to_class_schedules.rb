class AddGradePendencyToClassSchedules < ActiveRecord::Migration[7.0]
  def change
    add_column :class_schedules, :grade_pendency, :datetime, precision: nil
  end
end
