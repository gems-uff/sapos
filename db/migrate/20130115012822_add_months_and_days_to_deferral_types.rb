class AddMonthsAndDaysToDeferralTypes < ActiveRecord::Migration
  def self.up
    rename_column :deferral_types, :duration, :duration_semesters
    add_column :deferral_types, :duration_months, :integer, :default => 0
    add_column :deferral_types, :duration_days, :integer, :default => 0
  end

  def self.down
    rename_column :deferral_types, :duration_semesters, :duration
    remove_column :deferral_types, :duration_months
    remove_column :deferral_types, :duration_days
  end
end
