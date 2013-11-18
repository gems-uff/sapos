class AddDefenseDateToEnrollments < ActiveRecord::Migration
  def change
    add_column :enrollments, :thesis_defense_date, :date
  end
end
