class AddEnrollmentNumberToProfessors < ActiveRecord::Migration
  def self.up
    add_column :professors, :enrollment_number, :string
  end

  def self.down
    remove_column :professors, :enrollment_number
  end
end
