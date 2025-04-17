class AddGradesDeadlineToClassSchedule < ActiveRecord::Migration[7.0]
  def change
    add_column :class_schedules, :grades_deadline, :datetime, precision: nil
    reversible do |dir|
      dir.up do
        ClassSchedule.find_each do |schedule|
          schedule.update!(grades_deadline: schedule.period_start + 116.days)
        end
      end
    end
  end
end
