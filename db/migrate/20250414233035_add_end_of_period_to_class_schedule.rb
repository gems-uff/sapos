class AddEndOfPeriodToClassSchedule < ActiveRecord::Migration[7.0]
  def change
    add_column :class_schedules, :period_end, :datetime, precision: nil
    reversible do |dir|
      dir.up do
        ClassSchedule.find_each do |schedule|
          schedule.update!(period_end: schedule.period_start + 109.days)
        end
      end
    end
  end
end
