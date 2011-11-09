class AddCancelDateToScholarshipDuration < ActiveRecord::Migration
  def self.up
    add_column :scholarship_durations, :cancel_date, :date
  end

  def self.down
    remove_column :scholarship_durations, :cancel_date
  end
end
