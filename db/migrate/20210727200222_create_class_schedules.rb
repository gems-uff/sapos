class CreateClassSchedules < ActiveRecord::Migration[6.0]
  def change
    create_table :class_schedules do |t|
      t.integer :year
      t.integer :semester
      t.datetime :enrollment_start
      t.datetime :enrollment_end

      t.timestamps
    end
  end
end
