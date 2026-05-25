class RemoveActiveFromEnrollmentHolds < ActiveRecord::Migration[7.1]
  def up
    remove_column :enrollment_holds, :active, :boolean
  end

  def down
    add_column :enrollment_holds, :active, :boolean, default: false, null: false
    EnrollmentHold.find_each do |eh|
      eh.update!(active: true) if eh.active?
    end
  end
end
