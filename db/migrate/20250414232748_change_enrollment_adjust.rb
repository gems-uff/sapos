class ChangeEnrollmentAdjust < ActiveRecord::Migration[7.0]
  def change
    rename_column :class_schedules, :enrollment_adjust, :period_start
  end
end
