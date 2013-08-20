class AddDefaultValueToSemesters < ActiveRecord::Migration
  def self.up
    DeferralType.transaction do
      DeferralType.where(:duration_semesters => nil).update_all(:duration_semesters => 0)
      PhaseDuration.where(:deadline_semesters => nil).update_all(:deadline_semesters => 0)
      change_column :deferral_types, :duration_semesters, :integer, :default => 0
      change_column :phase_durations, :deadline_semesters, :integer, :default => 0
    end
  end

  def self.down
    change_column :deferral_types, :duration_semesters, :integer, :default => nil
    change_column :phase_durations, :deadline_semesters, :integer, :default => nil
  end
end
