class AddActiveToEnrollmentHolds < ActiveRecord::Migration
  def change
    add_column :enrollment_holds, :active, :boolean, :default => true
  end
end
