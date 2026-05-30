class AddEndOfPeriodAndGradesDeadlineToClassSchedule < ActiveRecord::Migration[7.0]
  def change
    add_column :class_schedules, :period_end, :datetime, precision: nil
    add_column :class_schedules, :grades_deadline, :datetime, precision: nil
    reversible do |dir|
      dir.up do
        ClassSchedule.find_each do |schedule|
          schedule.update!(period_end: schedule.period_start + 110.days - 1.second, grades_deadline: schedule.period_start + 117.days - 1.second)
        end
      end
    end
  end
end
