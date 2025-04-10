class AddGradePendencyToClassSchedule < ActiveRecord::Migration[7.0]
  def change
    add_column :class_schedules, :grade_pendency, :datetime, precision: nil
    reversible do |dir|
      dir.up do
        ClassSchedule.find_each do |schedule|
          schedule.update!(grade_pendency: schedule.enrollment_start + 3.months)
        end
      end
    end
  end
end
